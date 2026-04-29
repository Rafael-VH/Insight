import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({super.key});

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  final SupabaseClient _client = Supabase.instance.client;
  List<dynamic> _tables = [];
  bool _loadingTables = true;
  String? _tableError;

  @override
  void initState() {
    super.initState();
    _fetchTables();
  }

  Future<void> _fetchTables() async {
    try {
      // Intentamos obtener las tablas del esquema público
      // Nota: Esto puede fallar si el rol anon no tiene permisos sobre information_schema
      final response = await _client
          .from('information_schema.tables')
          .select('table_name')
          .eq('table_schema', 'public');

      setState(() {
        _tables = response as List<dynamic>;
        _loadingTables = false;
      });
    } catch (e) {
      setState(() {
        _tableError = e.toString();
        _loadingTables = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // En versiones recientes, la URL se encuentra en el cliente REST
    final projectUrl = _client.rest.url.toString();
    final uri = Uri.parse(projectUrl);
    final host = uri.host;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Debug Info'),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Información del Proyecto'),
            _buildInfoCard('URL', projectUrl),
            _buildInfoCard('Project ID', host.split('.').first),

            const SizedBox(height: 24),
            _buildSectionTitle('Tablas Detectadas (Esquema Público)'),
            if (_loadingTables)
              const Center(child: CircularProgressIndicator())
            else if (_tableError != null)
              _buildErrorCard(
                'No se pudieron listar las tablas (Permisos RLS/Schema).\nError: $_tableError',
              )
            else
              _buildTableList(),

            const SizedBox(height: 24),
            _buildSectionTitle('Contenido de Tabla "todos"'),
            _buildTodosPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF059669),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value),
        leading: const Icon(Icons.info_outline, color: Colors.blue),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableList() {
    if (_tables.isEmpty)
      return const Text('No se encontraron tablas públicas.');
    return Card(
      child: Column(
        children: _tables
            .map(
              (t) => ListTile(
                title: Text(t['table_name']),
                leading: const Icon(
                  Icons.table_chart_outlined,
                  color: Colors.orange,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTodosPreview() {
    return FutureBuilder(
      future: _client.from('todos').select(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildErrorCard('Error al leer "todos": ${snapshot.error}');
        }
        final data = snapshot.data as List<dynamic>?;
        if (data == null || data.isEmpty) {
          return const Card(
            child: ListTile(title: Text('Tabla "todos" vacía o inaccesible.')),
          );
        }
        return Card(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return ListTile(
                title: Text(item['name'] ?? 'Sin nombre'),
                subtitle: Text('ID: ${item['id']}'),
                leading: const Icon(
                  Icons.check_box_outlined,
                  color: Colors.green,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
