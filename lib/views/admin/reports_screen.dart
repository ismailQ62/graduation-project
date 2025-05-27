import 'package:flutter/material.dart';
import 'package:lorescue/models/user_model.dart';
import 'package:lorescue/models/zone_model.dart';
import 'package:lorescue/models/channel_model.dart';
import 'package:lorescue/services/database/database_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _dbService = DatabaseService();
  List<User> _users = [];
  List<Zone> _zones = [];
  List<Channel> _channels = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final userMaps = await _dbService.getUsers();
    final zoneMaps = await _dbService.getZones();
    final channelMaps = await _dbService.getAllChannels();
    setState(() {
      _users = userMaps.map((u) => User.fromMap(u)).toList();
      _zones = zoneMaps.map((z) => Zone.fromMap(z)).toList();
      _channels = channelMaps.map((c) => Channel.fromMap(c)).toList();
    });
  }

  Future<void> _exportPdf(String title, List<List<String>> data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build:
            (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: data.isNotEmpty ? data.first : [],
                  data: data.length > 1 ? data.sublist(1) : [],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  border: pw.TableBorder.all(),
                ),
              ],
            ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Reports"),
        bottom: TabBar(
          isScrollable: true,
          controller: _tabController,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Zones'),
            Tab(text: 'Channels'),
            Tab(text: 'Activity Logs'),
            Tab(text: 'System Usage statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserReport(),
          _buildZoneReport(),
          _buildChannelReport(),
          _buildActivityLogs(),
          _buildUsageStats(),
        ],
      ),
    );
  }

  Widget _buildUserReport() {
    final data = [
      ["Name", "National ID", "Role"],
      ..._users.map((u) => [u.name, u.nationalId, u.role]),
    ];
    return _buildListWithExport("Users Report", data);
  }

  Widget _buildZoneReport() {
    final data = [
      ["ID", "Name"],
      ..._zones.map((z) => [z.id, z.name]),
    ];
    return _buildListWithExport("Zones Report", data);
  }

  Widget _buildChannelReport() {
    final data = [
      ["ID", "Name"],
      ..._channels.map((c) => [c.id.toString(), c.name]),
    ];
    return _buildListWithExport("Channels Report", data);
  }

  Widget _buildActivityLogs() {
    final logs = _users.map((u) => [u.name, u.nationalId, 'Logged In']);
    final data = [
      ['User', 'ID', 'Activity'],
      ...logs,
    ];
    return _buildListWithExport(" Activity Logs", data);
  }

  Widget _buildUsageStats() {
    final Map<String, int> roleCount = {};
    for (var u in _users) {
      roleCount[u.role] = (roleCount[u.role] ?? 0) + 1;
    }
    final data = [
      ['Role', 'Count'],
      ...roleCount.entries.map((e) => [e.key, e.value.toString()]),
    ];
    return _buildListWithExport("Statistics", data);
  }

  Widget _buildListWithExport(String title, List<List<String>> data) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Export"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _exportPdf(title, data),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: data.length - 1,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final row = data[index + 1];
                  return ListTile(
                    leading: const Icon(
                      Icons.circle,
                      size: 10,
                      color: Colors.blueAccent,
                    ),
                    title: Text(
                      row.join("  •  "),
                      style: const TextStyle(fontSize: 14),
                    ),
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatTimestamp(dynamic timestamp) {
  try {
    final dt = DateTime.tryParse(timestamp.toString());
    if (dt != null) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}, ${dt.day}/${dt.month}/${dt.year}';
    }
  } catch (_) {}
  return timestamp.toString();
}
