/// What the backend found in an uploaded stock file, before anything is
/// changed: the figures the analysis card shows, and the id to confirm (or
/// cancel) the import with.
class InventoryImportPreview {
  /// The import's UUID.
  final String importId;
  final int totalCount;

  /// Rows that match a medicine the pharmacy already has.
  final int updatedCount;

  /// Rows that match nothing yet (they need a decision before they are added).
  final int newCount;
  final int errorCount;

  /// False when the backend will refuse to confirm the import as it is.
  final bool canCommit;

  const InventoryImportPreview({
    required this.importId,
    required this.totalCount,
    required this.newCount,
    required this.updatedCount,
    required this.errorCount,
    this.canCommit = true,
  });
}
