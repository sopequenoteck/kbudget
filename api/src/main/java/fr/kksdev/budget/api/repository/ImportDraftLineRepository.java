package fr.kksdev.budget.api.repository;

import fr.kksdev.budget.api.model.ImportDraftLine;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ImportDraftLineRepository extends JpaRepository<ImportDraftLine, UUID> {

    List<ImportDraftLine> findByDraftIdOrderByLineNumberAsc(UUID draftId);
}
