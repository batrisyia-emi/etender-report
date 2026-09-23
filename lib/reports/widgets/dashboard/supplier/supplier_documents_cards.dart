// lib/reports/widgets/dashboard/supplier/supplier_documents_cards.dart
//
// The Documents tab: the expiry banner, the mandatory list, and the two
// summary cards beside it.
import 'package:flutter/material.dart';

import 'package:etender_reports/reports/models/supplier_dashboard_metrics.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_cards.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_primitives.dart';
import 'package:etender_reports/reports/widgets/dashboard/dashboard_theme.dart';
import 'package:etender_reports/shared/utils/formatters.dart';

class SupplierExpiryBanner extends StatelessWidget {
  const SupplierExpiryBanner({
    super.key,
    required this.documents,
    required this.now,
    required this.onDismiss,
  });

  final List<Map<String, dynamic>> documents;
  final DateTime now;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final detail = documents
        .map((d) {
          final days = supplierDaysToExpiry(d, now);
          return '${d['name']} expires in $days days';
        })
        .join('. ');

    return Container(
      decoration: BoxDecoration(
        color: DashTheme.tintOf(DashTheme.danger),
        border: Border.all(color: DashTheme.danger.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(DashTheme.radius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: DashTheme.danger,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${documents.length} '
                  '${documents.length == 1 ? 'document' : 'documents'} '
                  'expiring soon',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: DashTheme.danger,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$detail. Please renew and re-upload.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: DashTheme.text,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          DashButton(label: 'Dismiss', onTap: onDismiss),
        ],
      ),
    );
  }
}

class SupplierMandatoryDocumentsCard extends StatelessWidget {
  const SupplierMandatoryDocumentsCard({
    super.key,
    required this.documents,
    required this.now,
    required this.onUploadNew,
    required this.onUpload,
    required this.onRenew,
  });

  final List<Map<String, dynamic>> documents;
  final DateTime now;

  /// Adds a file on the supplier's own account rather than filling one of
  /// the mandatory slots, so it carries no document name.
  final VoidCallback onUploadNew;

  /// Both take the document's name, which is what identifies the slot the
  /// supplier pressed.
  final ValueChanged<String> onUpload;
  final ValueChanged<String> onRenew;

  @override
  Widget build(BuildContext context) {
    final uploaded = supplierUploadedCount(documents);

    return DashCard(
      icon: Icons.folder_outlined,
      title: 'Mandatory Documents',
      subtitle: '$uploaded of ${documents.length} complete',
      padded: false,
      trailing: DashButton(
        label: 'Upload new',
        onTap: onUploadNew,
        filled: true,
      ),
      child: Column(
        children: [
          for (final document in documents)
            SupplierDocumentItem(
              document: document,
              now: now,
              onUpload: onUpload,
              onRenew: onRenew,
            ),
        ],
      ),
    );
  }
}

class SupplierDocumentItem extends StatelessWidget {
  const SupplierDocumentItem({
    super.key,
    required this.document,
    required this.now,
    required this.onUpload,
    required this.onRenew,
  });

  final Map<String, dynamic> document;
  final DateTime now;
  final ValueChanged<String> onUpload;
  final ValueChanged<String> onRenew;

  /// The template tints the file square by format, and greys the ones
  /// that were never uploaded.
  static Color _formatColor(Object? fileType) => switch (fileType?.toString()) {
    'PDF' => DashTheme.danger,
    'XLSX' => DashTheme.success,
    'DOCX' => DashTheme.info,
    _ => DashTheme.muted,
  };

  static IconData _formatIcon(Object? fileType) =>
      switch (fileType?.toString()) {
        'XLSX' => Icons.table_chart_outlined,
        'DOCX' => Icons.description_outlined,
        'PDF' => Icons.picture_as_pdf_outlined,
        _ => Icons.upload_file_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final status = supplierDocumentStatus(document, now);
    final days = supplierDaysToExpiry(document, now);

    final (statusLabel, statusColor) = switch (status) {
      SupplierDocumentStatus.critical => ('Critical', DashTheme.danger),
      SupplierDocumentStatus.expiring => ('Expiring', DashTheme.warning),
      SupplierDocumentStatus.valid => ('Valid', DashTheme.success),
      SupplierDocumentStatus.missing => ('Missing', DashTheme.muted),
    };

    final meta = status == SupplierDocumentStatus.missing
        ? 'Not uploaded'
        : 'Uploaded ${formatDateOnly(document['uploadedDate'])} · '
              '${document['fileType']} · ${document['fileSize']}';

    final expiry = switch (status) {
      SupplierDocumentStatus.missing => null,
      _ when days == null => 'No expiry',
      SupplierDocumentStatus.valid =>
        'Valid until ${formatDateOnly(document['expiryDate'])}',
      _ => 'Expires ${formatDateOnly(document['expiryDate'])} ($days days)',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DashTheme.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: DashTheme.tintOf(_formatColor(document['fileType'])),
              borderRadius: BorderRadius.circular(DashTheme.radius),
            ),
            child: Icon(
              _formatIcon(document['fileType']),
              size: 17,
              color: _formatColor(document['fileType']),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  document['name']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: DashTheme.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: DashTheme.muted),
                ),
                if (expiry != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    expiry,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              DashPill(label: statusLabel, color: statusColor),
              if (status != SupplierDocumentStatus.valid) ...[
                const SizedBox(height: 5),
                DashButton(
                  label: status == SupplierDocumentStatus.missing
                      ? 'Upload'
                      : status == SupplierDocumentStatus.critical
                      ? 'Renew now'
                      : 'Renew',
                  onTap: () {
                    final name = document['name']?.toString() ?? '';
                    status == SupplierDocumentStatus.missing
                        ? onUpload(name)
                        : onRenew(name);
                  },
                  // Only the two that actually block you are pushed.
                  filled: status != SupplierDocumentStatus.expiring,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class SupplierCompletenessCard extends StatelessWidget {
  const SupplierCompletenessCard({
    super.key,
    required this.documents,
    required this.now,
  });

  final List<Map<String, dynamic>> documents;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final uploaded = supplierUploadedCount(documents);
    final missing = documents.length - uploaded;

    int count(SupplierDocumentStatus status) =>
        supplierDocumentsWith(documents, now, status);

    return DashCard(
      icon: Icons.fact_check_outlined,
      title: 'Document Completeness',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$uploaded / ${documents.length}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: missing == 0 ? DashTheme.success : DashTheme.primary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Documents uploaded',
                  style: TextStyle(fontSize: 11.5, color: DashTheme.muted),
                ),
              ),
              if (missing > 0)
                DashPill(label: '$missing missing', color: DashTheme.warning),
            ],
          ),
          const SizedBox(height: 14),
          SupplierCountRow(
            label: 'Valid',
            value: '${count(SupplierDocumentStatus.valid)} docs',
            color: DashTheme.success,
          ),
          const SizedBox(height: 7),
          SupplierCountRow(
            label: 'Expiring soon',
            value: '${count(SupplierDocumentStatus.expiring)} docs',
            color: DashTheme.warning,
          ),
          const SizedBox(height: 7),
          SupplierCountRow(
            label: 'Critical',
            value: '${count(SupplierDocumentStatus.critical)} docs',
            color: DashTheme.danger,
          ),
          const SizedBox(height: 7),
          SupplierCountRow(
            label: 'Not uploaded',
            value: '${count(SupplierDocumentStatus.missing)} docs',
            color: DashTheme.muted,
          ),
        ],
      ),
    );
  }
}

class SupplierCountRow extends StatelessWidget {
  const SupplierCountRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: DashTheme.text),
        ),
      ],
    );
  }
}

class SupplierRecentUploadsCard extends StatelessWidget {
  const SupplierRecentUploadsCard({super.key, required this.documents});

  final List<Map<String, dynamic>> documents;

  @override
  Widget build(BuildContext context) {
    final recent = supplierRecentUploads(documents);

    return DashCard(
      icon: Icons.upload_file_outlined,
      title: 'Recent Uploads',
      child: recent.isEmpty
          ? const Text(
              'Nothing uploaded yet.',
              style: TextStyle(fontSize: 12, color: DashTheme.muted),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < recent.length && i < 5; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          recent[i]['fileName']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: DashTheme.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        formatDateOnly(recent[i]['uploadedDate']),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: DashTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
