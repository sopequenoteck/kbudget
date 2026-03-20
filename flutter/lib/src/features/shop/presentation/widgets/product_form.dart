import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:k_budget/src/common_widgets/app_form_field.dart';
import 'package:k_budget/src/constants/app_radius.dart';
import 'package:k_budget/src/constants/app_spacing.dart';
import 'package:k_budget/src/domain/models/product.dart';
import 'package:k_budget/src/constants/app_typography.dart';
import 'package:k_budget/src/theme/app_theme_extension.dart';
import 'package:k_budget/src/utils/amount_formatter.dart';
import 'package:k_budget/src/utils/decimal_input_formatter.dart';
import 'package:k_budget/src/utils/image_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProductForm extends ConsumerStatefulWidget {
  const ProductForm({
    super.key,
    this.product,
    required this.onSaved,
    required this.onCancelled,
  });

  final Product? product;
  final Future<void> Function(Product product) onSaved;
  final VoidCallback onCancelled;

  @override
  ConsumerState<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<ProductForm> {
  late final TextEditingController _nomController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _prixAchatController;
  late final TextEditingController _prixVenteController;
  late final TextEditingController _stockController;

  String? _localImagePath;
  String? _imageDataUri; // base64 data URI pour l'API
  bool _showErrors = false;
  bool _isSubmitting = false;
  bool _initialized = false;

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _descriptionController = TextEditingController();
    _prixAchatController = TextEditingController();
    _prixVenteController = TextEditingController();
    _stockController = TextEditingController();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _prixAchatController.dispose();
    _prixVenteController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _initFromEntity() {
    if (_initialized) return;
    _initialized = true;

    final product = widget.product;
    if (product != null) {
      _nomController.text = product.nom;
      _descriptionController.text = product.description ?? '';
      _prixAchatController.text = product.prixAchat.toString();
      _prixVenteController.text = product.prixVente.toString();
      _stockController.text = product.stock.toString();
      if (product.imageUrl != null) {
        if (ImageUtils.isBase64DataUri(product.imageUrl)) {
          _imageDataUri = product.imageUrl;
        } else {
          final file = File(product.imageUrl!);
          if (file.existsSync()) {
            _localImagePath = product.imageUrl;
            _imageDataUri = ImageUtils.fileToBase64DataUri(file);
          }
        }
      }
    }
  }

  // --- Validation ---

  String? _validateNom() {
    final value = _nomController.text.trim();
    if (value.isEmpty) return 'Le nom est obligatoire';
    if (value.length > 100) return '100 caractères maximum';
    return null;
  }

  String? _validateDescription() {
    final value = _descriptionController.text.trim();
    if (value.length > 500) return '500 caractères maximum';
    return null;
  }

  String? _validatePrixAchat() {
    final value = _prixAchatController.text.trim();
    if (value.isEmpty) return "Le prix d'achat est obligatoire";
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return "Le prix d'achat doit être supérieur à 0";
    }
    return null;
  }

  String? _validatePrixVente() {
    final value = _prixVenteController.text.trim();
    if (value.isEmpty) return 'Le prix de vente est obligatoire';
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) {
      return 'Le prix de vente doit être supérieur à 0';
    }
    return null;
  }

  String? _validateStock() {
    if (_isEditMode) return null;
    final value = _stockController.text.trim();
    if (value.isEmpty) return 'Le stock est obligatoire';
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0) {
      return 'Le stock doit être supérieur ou égal à 0';
    }
    return null;
  }

  bool _isValid() {
    return _validateNom() == null &&
        _validateDescription() == null &&
        _validatePrixAchat() == null &&
        _validatePrixVente() == null &&
        _validateStock() == null;
  }

  // --- Actions ---

  Future<void> _onSubmit() async {
    setState(() => _showErrors = true);
    if (!_isValid()) return;

    setState(() => _isSubmitting = true);

    final product = Product(
      id: widget.product?.id ?? '',
      nom: _nomController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      icone: widget.product?.icone,
      imageUrl: _imageDataUri,
      prixAchat: double.parse(_prixAchatController.text.trim()),
      prixVente: double.parse(_prixVenteController.text.trim()),
      stock: _isEditMode
          ? widget.product!.stock
          : int.parse(_stockController.text.trim()),
      totalVendu: widget.product?.totalVendu ?? 0,
      actif: widget.product?.actif ?? true,
    );

    try {
      await widget.onSaved(product);
    } on Exception {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sauvegarde')),
      );
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const PhosphorIcon(PhosphorIconsRegular.camera, size: 20),
              title: const Text('Caméra'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const PhosphorIcon(PhosphorIconsRegular.image, size: 20),
              title: const Text('Galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_localImagePath != null || _imageDataUri != null)
              ListTile(
                leading: const PhosphorIcon(PhosphorIconsRegular.trash, size: 20),
                title: const Text('Supprimer'),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final productsDir = Directory('${appDir.path}/products');
      if (!productsDir.existsSync()) {
        productsDir.createSync(recursive: true);
      }

      final ext = picked.path.contains('.')
          ? '.${picked.path.split('.').last}'
          : '';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final destPath = '${productsDir.path}/$fileName';

      final destFile = await File(picked.path).copy(destPath);
      _imageDataUri = ImageUtils.fileToBase64DataUri(destFile);

      // Delete old file if replacing
      if (_localImagePath != null) {
        final oldFile = File(_localImagePath!);
        if (oldFile.existsSync()) {
          oldFile.deleteSync();
        }
      }

      setState(() => _localImagePath = destPath);
    } on Exception {
      // Permission denied or picker cancelled — silent no-op
    }
  }

  void _removeImage() {
    if (_localImagePath != null) {
      final file = File(_localImagePath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    setState(() {
      _localImagePath = null;
      _imageDataUri = null;
    });
  }

  // --- Widgets ---

  Widget _buildMargeIndicateur() {
    final prixAchat = double.tryParse(_prixAchatController.text);
    final prixVente = double.tryParse(_prixVenteController.text);

    if (prixAchat == null || prixVente == null) {
      return const SizedBox.shrink();
    }

    final marge = prixVente - prixAchat;
    final colors = Theme.of(context).extension<AppThemeExtension>()!;
    final margeColor = marge >= 0 ? colors.incomeColor : colors.expenseColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: Row(
        children: [
          Text(
            'Marge : ',
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            AmountFormatter.format(marge),
            style: TextStyle(
              fontSize: AppTypography.sizeSm,
              fontWeight: AppTypography.semiBold,
              color: margeColor,
            ),
          ),
        ],
      ),
    );
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    _initFromEntity();

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Image picker area
        Center(
          child: GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: _localImagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Image.file(
                        File(_localImagePath!),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _imageDataUri != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: Image.memory(
                            ImageUtils.base64DataUriToBytes(_imageDataUri!),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                      : PhosphorIcon(
                          PhosphorIconsRegular.camera,
                          color: colorScheme.onSurfaceVariant,
                        ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Nom
        AppFormField(
          label: 'Nom',
          showError: _showErrors && _validateNom() != null,
          errorMessage: _validateNom() ?? '',
          child: TextField(
            controller: _nomController,
            decoration:
                const InputDecoration.collapsed(hintText: 'Nom du produit'),
            maxLength: 100,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (
              _, {
              required currentLength,
              required isFocused,
              maxLength,
            }) =>
                null,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),

        // Prix d'achat + Prix de vente (côte à côte)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppFormField(
                label: "Prix d'achat",
                showError: _showErrors && _validatePrixAchat() != null,
                errorMessage: _validatePrixAchat() ?? '',
                child: TextField(
                  controller: _prixAchatController,
                  decoration: const InputDecoration.collapsed(hintText: '0.00'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                    DecimalTextInputFormatter(),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: AppFormField(
                label: 'Prix de vente',
                showError: _showErrors && _validatePrixVente() != null,
                errorMessage: _validatePrixVente() ?? '',
                child: TextField(
                  controller: _prixVenteController,
                  decoration: const InputDecoration.collapsed(hintText: '0.00'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                    DecimalTextInputFormatter(),
                  ],
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),

        // Margin indicator
        _buildMargeIndicateur(),

        // Stock initial (création uniquement)
        if (!_isEditMode) ...[
          AppFormField(
            label: 'Stock initial',
            showError: _showErrors && _validateStock() != null,
            errorMessage: _validateStock() ?? '',
            child: TextField(
              controller: _stockController,
              decoration: const InputDecoration.collapsed(hintText: '0'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
        ],

        // Description
        AppFormField(
          label: 'Description',
          showError: _showErrors && _validateDescription() != null,
          errorMessage: _validateDescription() ?? '',
          child: TextField(
            controller: _descriptionController,
            decoration: const InputDecoration.collapsed(
              hintText: 'Description (optionnel)',
            ),
            maxLines: 3,
            minLines: 2,
            maxLength: 500,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter: (
              _, {
              required currentLength,
              required isFocused,
              maxLength,
            }) =>
                null,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        const SizedBox(height: AppSpacing.space6),

        // Action buttons
        Row(
          children: [
            const Spacer(),
            OutlinedButton(
              onPressed: _isSubmitting ? null : widget.onCancelled,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: AppSpacing.space3),
            FilledButton(
              onPressed: _isSubmitting ? null : _onSubmit,
              child: _isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Text(_isEditMode ? 'Modifier' : 'Enregistrer'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
      ],
    );
  }
}
