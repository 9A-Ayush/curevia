import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/medical_document_provider.dart';
import '../../models/medical_document_model.dart';
import '../../widgets/medical_document_card.dart';
import '../../widgets/document_upload_dialog.dart';
import '../../widgets/document_filter_sheet.dart';
import 'document_viewer_screen.dart';

/// Medical documents screen for patients
class MedicalDocumentsScreen extends ConsumerStatefulWidget {
  const MedicalDocumentsScreen({super.key});

  @override
  ConsumerState<MedicalDocumentsScreen> createState() => _MedicalDocumentsScreenState();
}

class _MedicalDocumentsScreenState extends ConsumerState<MedicalDocumentsScreen> {
  final String _patientId = 'current_patient_id'; // TODO: Get from auth provider
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final documentNotifier = ref.read(medicalDocumentProvider.notifier);
    documentNotifier.loadDocuments(patientId: _patientId);
    documentNotifier.loadStatistics(patientId: _patientId);
  }

  @override
  Widget build(BuildContext context) {
    final documentState = ref.watch(medicalDocumentProvider);
    final documentsStreamAsync = ref.watch(documentsStreamProvider({
      'patientId': _patientId,
      'category': documentState.selectedCategory,
      'documentType': documentState.selectedType,
      'status': DocumentStatus.active,
    }));

    // Listen to state changes
    ref.listen<MedicalDocumentState>(medicalDocumentProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(medicalDocumentProvider.notifier).clearError();
      }

      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: AppColors.success,
          ),
        );
        ref.read(medicalDocumentProvider.notifier).clearSuccessMessage();
      }
    });

    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Medical Documents'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(medicalDocumentProvider.notifier).clearSearch();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_isSearching) _buildSearchBar(),

          // Statistics summary
          _buildStatisticsSummary(),

          // Filter chips
          _buildFilterChips(),

          // Documents list
          Expanded(
            child: _buildDocumentsList(documentsStreamAsync),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getPrimaryColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search documents...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (query) {
          if (query.isNotEmpty) {
            ref.read(medicalDocumentProvider.notifier).searchDocuments(
              patientId: _patientId,
              query: query,
            );
          } else {
            ref.read(medicalDocumentProvider.notifier).clearSearch();
          }
        },
      ),
    );
  }

  /// Build statistics summary
  Widget _buildStatisticsSummary() {
    final statistics = ref.watch(documentStatisticsProvider(_patientId));

    return statistics.when(
      data: (stats) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Total Documents',
              stats.totalDocuments.toString(),
              Icons.description,
              AppColors.primary,
            ),
            _buildStatItem(
              'Total Size',
              stats.totalSizeFormatted,
              Icons.storage,
              AppColors.info,
            ),
            _buildStatItem(
              'Categories',
              stats.categoryCount.length.toString(),
              Icons.category,
              AppColors.success,
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 80),
      error: (error, stack) => const SizedBox(height: 80),
    );
  }

  /// Build stat item
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Build filter chips
  Widget _buildFilterChips() {
    final documentState = ref.watch(medicalDocumentProvider);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Category filter
          if (documentState.selectedCategory != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(documentState.selectedCategory!.displayName),
                selected: true,
                onSelected: (_) {
                  ref.read(medicalDocumentProvider.notifier).filterByCategory(null);
                  _loadInitialData();
                },
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  ref.read(medicalDocumentProvider.notifier).filterByCategory(null);
                  _loadInitialData();
                },
              ),
            ),

          // Type filter
          if (documentState.selectedType != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(documentState.selectedType!.displayName),
                selected: true,
                onSelected: (_) {
                  ref.read(medicalDocumentProvider.notifier).filterByType(null);
                  _loadInitialData();
                },
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  ref.read(medicalDocumentProvider.notifier).filterByType(null);
                  _loadInitialData();
                },
              ),
            ),

          // Add filter button
          ActionChip(
            label: const Text('Add Filter'),
            avatar: const Icon(Icons.add, size: 16),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
    );
  }

  /// Build documents list
  Widget _buildDocumentsList(AsyncValue<List<MedicalDocument>> documentsAsync) {
    final documentState = ref.watch(medicalDocumentProvider);

    // Show search results if searching
    if (_isSearching && documentState.searchQuery.isNotEmpty) {
      return _buildSearchResults(documentState.searchResults);
    }

    return documentsAsync.when(
      data: (documents) {
        if (documents.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async => _loadInitialData(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              return MedicalDocumentCard(
                document: document,
                onTap: () => _viewDocument(document),
                onEdit: () => _editDocument(document),
                onDelete: () => _deleteDocument(document),
                onShare: () => _shareDocument(document),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error loading documents',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build search results
  Widget _buildSearchResults(List<MedicalDocument> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No documents found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final document = results[index];
        return MedicalDocumentCard(
          document: document,
          onTap: () => _viewDocument(document),
          onEdit: () => _editDocument(document),
          onDelete: () => _deleteDocument(document),
          onShare: () => _shareDocument(document),
        );
      },
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No documents yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your first medical document to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showUploadDialog,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Show upload dialog
  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => DocumentUploadDialog(
        patientId: _patientId,
        onUploadComplete: () {
          _loadInitialData();
        },
      ),
    );
  }

  /// Show filter sheet
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DocumentFilterSheet(
        currentCategory: ref.read(medicalDocumentProvider).selectedCategory,
        currentType: ref.read(medicalDocumentProvider).selectedType,
        onApplyFilters: (category, type) {
          final notifier = ref.read(medicalDocumentProvider.notifier);
          notifier.filterByCategory(category);
          notifier.filterByType(type);
          _loadInitialData();
        },
      ),
    );
  }

  /// View document
  void _viewDocument(MedicalDocument document) {
    // Record view
    ref.read(medicalDocumentProvider.notifier).recordView(document.id);

    // Navigate to document viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentViewerScreen(document: document),
      ),
    );
  }

  /// Edit document
  void _editDocument(MedicalDocument document) {
    showDialog(
      context: context,
      builder: (context) => DocumentUploadDialog(
        patientId: _patientId,
        document: document,
        onUploadComplete: () {
          _loadInitialData();
        },
      ),
    );
  }

  /// Delete document
  void _deleteDocument(MedicalDocument document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.originalFileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(medicalDocumentProvider.notifier).deleteDocument(
                documentId: document.id,
                patientId: _patientId,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Share document
  void _shareDocument(MedicalDocument document) {
    // TODO: Implement document sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document sharing feature coming soon!'),
      ),
    );
  }
}