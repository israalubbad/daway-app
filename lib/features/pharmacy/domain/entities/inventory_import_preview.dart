/// What the backend found in an uploaded stock file, before anything is
/// changed: the figures the analysis card shows, and the id to confirm (or
/// cancel) the import with.
class InventoryImportPreview {
  final int importId;
  final int totalCount;
  final int newCount;
  final int updatedCount;
  final int errorCount;

  const InventoryImportPreview({
    required this.importId,
    required this.totalCount,
    required this.newCount,
    required this.updatedCount,
    required this.errorCount,
  });
}
