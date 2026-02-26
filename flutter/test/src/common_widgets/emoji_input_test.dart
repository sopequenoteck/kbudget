import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_budget/src/common_widgets/emoji_input.dart';
import 'package:k_budget/src/theme/app_theme.dart';

Future<void> pumpEmojiInput(
  WidgetTester tester,
  Widget widget, {
  ThemeData? theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(body: Center(child: widget)),
    ),
  );
}

void main() {
  // =====================================================
  // US1 — Sélection via le picker visuel
  // =====================================================
  group('US1 - Sélection via picker', () {
    testWidgets(
      'should_display_placeholder_when_no_initial_value',
      (tester) async {
        await pumpEmojiInput(
          tester,
          EmojiInput(
            label: 'Icône',
            onChanged: (_) {},
          ),
        );

        expect(find.text('...'), findsOneWidget);
        expect(find.text('Icône'), findsOneWidget);
      },
    );

    testWidgets(
      'should_display_emoji_when_initial_value_provided',
      (tester) async {
        await pumpEmojiInput(
          tester,
          Form(
            child: EmojiInput(
              label: 'Icône',
              initialValue: '\u{1F3E0}',
              onChanged: (_) {},
            ),
          ),
        );

        expect(find.text('\u{1F3E0}'), findsOneWidget);
        expect(find.text('...'), findsNothing);
      },
    );

    testWidgets(
      'should_open_bottom_sheet_when_trigger_tapped',
      (tester) async {
        await pumpEmojiInput(
          tester,
          EmojiInput(
            label: 'Icône',
            onChanged: (_) {},
          ),
        );

        await tester.tap(find.text('...'));
        await tester.pumpAndSettle();

        expect(find.byType(EmojiPicker), findsOneWidget);
        expect(find.text('Choisir un emoji'), findsOneWidget);
      },
    );

    testWidgets(
      'should_close_bottom_sheet_and_update_value_when_emoji_selected',
      (tester) async {
        String? selectedEmoji;

        await pumpEmojiInput(
          tester,
          EmojiInput(
            label: 'Icône',
            onChanged: (emoji) => selectedEmoji = emoji,
          ),
        );

        // Open picker
        await tester.tap(find.text('...'));
        await tester.pumpAndSettle();

        // Verify picker is open
        expect(find.byType(EmojiPicker), findsOneWidget);

        // Simulate emoji selection via the onEmojiSelected callback
        final emojiPicker = tester.widget<EmojiPicker>(
          find.byType(EmojiPicker),
        );
        emojiPicker.onEmojiSelected!(
          Category.SMILEYS,
          Emoji('\u{1F600}', 'grinning face'),
        );
        await tester.pumpAndSettle();

        // Bottom sheet should be closed
        expect(find.byType(EmojiPicker), findsNothing);
        // Value should be updated
        expect(selectedEmoji, '\u{1F600}');
        // Trigger should show the selected emoji
        expect(find.text('\u{1F600}'), findsOneWidget);
      },
    );
  });

  // =====================================================
  // US2 — Intégration formulaire avec validation
  // =====================================================
  group('US2 - Intégration formulaire', () {
    testWidgets(
      'should_show_error_message_when_validation_fails',
      (tester) async {
        final formKey = GlobalKey<FormState>();

        await pumpEmojiInput(
          tester,
          Form(
            key: formKey,
            child: EmojiInput(
              label: 'Icône',
              validator: (value) =>
                  value == null || value.isEmpty ? 'Icône requise' : null,
              onChanged: (_) {},
            ),
          ),
        );

        formKey.currentState!.validate();
        await tester.pumpAndSettle();

        expect(find.text('Icône requise'), findsOneWidget);
      },
    );

    testWidgets(
      'should_ignore_tap_when_disabled',
      (tester) async {
        await pumpEmojiInput(
          tester,
          EmojiInput(
            label: 'Icône',
            enabled: false,
            initialValue: '\u{1F512}',
            onChanged: (_) {},
          ),
        );

        // Emoji should still be visible
        expect(find.text('\u{1F512}'), findsOneWidget);

        // Opacity should be 0.5
        final opacity = tester.widget<Opacity>(find.byType(Opacity));
        expect(opacity.opacity, 0.5);

        // Tap should not open bottom sheet
        await tester.tap(find.text('\u{1F512}'));
        await tester.pumpAndSettle();

        expect(find.byType(EmojiPicker), findsNothing);
      },
    );

    testWidgets(
      'should_call_onChanged_when_emoji_selected',
      (tester) async {
        String? changedEmoji;

        await pumpEmojiInput(
          tester,
          EmojiInput(
            label: 'Icône',
            onChanged: (emoji) => changedEmoji = emoji,
          ),
        );

        // Open picker
        await tester.tap(find.text('...'));
        await tester.pumpAndSettle();

        // Simulate selection
        final emojiPicker = tester.widget<EmojiPicker>(
          find.byType(EmojiPicker),
        );
        emojiPicker.onEmojiSelected!(
          Category.SMILEYS,
          Emoji('\u{2764}', 'red heart'),
        );
        await tester.pumpAndSettle();

        expect(changedEmoji, '\u{2764}');
      },
    );

    testWidgets(
      'should_display_non_emoji_char_when_initial_value_is_not_emoji',
      (tester) async {
        await pumpEmojiInput(
          tester,
          Form(
            child: EmojiInput(
              label: 'Icône',
              initialValue: 'A',
              onChanged: (_) {},
            ),
          ),
        );

        expect(find.text('A'), findsOneWidget);
        expect(find.text('...'), findsNothing);
      },
    );

    testWidgets(
      'should_auto_validate_when_autovalidateMode_set',
      (tester) async {
        await pumpEmojiInput(
          tester,
          Form(
            child: EmojiInput(
              label: 'Icône',
              validator: (value) =>
                  value == null || value.isEmpty ? 'Requis' : null,
              autovalidateMode: AutovalidateMode.always,
              onChanged: (_) {},
            ),
          ),
        );

        // Error should show immediately without explicit validate() call
        await tester.pumpAndSettle();

        expect(find.text('Requis'), findsOneWidget);
      },
    );

    testWidgets(
      'should_call_onSaved_when_form_saved',
      (tester) async {
        final formKey = GlobalKey<FormState>();
        String? savedValue;

        await pumpEmojiInput(
          tester,
          Form(
            key: formKey,
            child: EmojiInput(
              label: 'Icône',
              initialValue: '\u{1F3E0}',
              onSaved: (value) => savedValue = value,
              onChanged: (_) {},
            ),
          ),
        );

        formKey.currentState!.save();

        expect(savedValue, '\u{1F3E0}');
      },
    );
  });

  // =====================================================
  // US3 — Recherche par mot-clé
  // =====================================================
  group('US3 - Recherche', () {
    testWidgets(
      'should_configure_search_view_in_picker',
      (tester) async {
        await pumpEmojiInput(
          tester,
          EmojiInput(
            label: 'Icône',
            onChanged: (_) {},
          ),
        );

        // Open picker
        await tester.tap(find.text('...'));
        await tester.pumpAndSettle();

        // Verify EmojiPicker is present with search config
        final emojiPicker = tester.widget<EmojiPicker>(
          find.byType(EmojiPicker),
        );
        expect(
          emojiPicker.config.searchViewConfig.hintText,
          'Rechercher un emoji...',
        );
      },
    );
  });

  // =====================================================
  // Polish — Dark theme
  // =====================================================
  group('Polish - Dark theme', () {
    testWidgets(
      'should_adapt_colors_to_dark_theme',
      (tester) async {
        await pumpEmojiInput(
          tester,
          EmojiInput(
            label: 'Icône',
            onChanged: (_) {},
          ),
          theme: AppTheme.dark,
        );

        // Verify the trigger container uses dark theme colors
        final containers = tester.widgetList<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        final triggerContainer = containers.first;
        final decoration = triggerContainer.decoration as BoxDecoration;
        expect(
          decoration.color,
          AppTheme.dark.colorScheme.surfaceContainerHighest,
        );
      },
    );
  });
}
