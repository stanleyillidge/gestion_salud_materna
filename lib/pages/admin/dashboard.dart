import 'package:flutter/material.dart';

import 'citas/appointment_management_screen.dart';
import 'pacientes/gestion_users.dart';
// Importa otras pantallas de gestión si las creas
// import 'recommendation_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  double get _kTabletBreakpoint => 600.0; // Cambia este valor según tus necesidades

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > _kTabletBreakpoint; // Mostrar FAB en pantallas pequeñas

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.logout),
          //   onPressed: () {
          //     // Lógica de Logout
          //     // FirebaseAuth.instance.signOut();
          //     // Navigator.of(context).pushReplacementNamed('/login');
          //   },
          // ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: isTablet ? 4 : 2, // 2 columnas en móvil, ajusta para tablet/web
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: <Widget>[
          _buildDashboardCard(
            context,
            icon: Icons.people_alt,
            title: 'Gestionar Usuarios',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                ),
          ),
          _buildDashboardCard(
            context,
            icon: Icons.calendar_month,
            title: 'Gestionar Citas',
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AppointmentManagementScreen()),
                ),
          ),
          // Añadir más tarjetas para otras gestiones
          _buildDashboardCard(
            context,
            icon: Icons.notes,
            title: 'Recomendaciones', // Placeholder
            onTap: () {
              /* Navegar a RecommendationManagementScreen */
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.medication,
            title: 'Medicamentos', // Placeholder
            onTap: () {
              /* Navegar a MedicationManagementScreen */
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4.0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50.0),
            const SizedBox(height: 10.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/* import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../models/modelos.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});
  static List<_ChartData> _createSampleData() {
    return [
      _ChartData('Doctor A', 30),
      _ChartData('Doctor B', 40),
      _ChartData('Doctor C', 50),
      // Agrega más datos según sea necesario
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: size.height * 0.85,
            minWidth: size.width * 0.9,
          ),
          child: Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  // maxHeight: size.height - 250.0,
                  maxWidth: !smallView ? 350.0 : size.width,
                ),
                child: const Column(
                  children: [
                    Text(
                      'Estadísticas',
                      style: TextStyle(fontSize: 24),
                    ),
                    SizedBox(height: 16),
                    StatisticTile(title: 'Total de Pacientes', value: '150'),
                    StatisticTile(title: 'Total de Doctores', value: '25'),
                    StatisticTile(title: 'Total de Citas Agendadas', value: '300'),
                  ],
                ),
              ),
              Column(
                children: [
                  const Text(
                    'Citas por Doctor',
                    style: TextStyle(fontSize: 24),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 200,
                      maxWidth: !smallView ? 400.0 : size.width,
                    ),
                    child: SfCartesianChart(
                      primaryXAxis: const CategoryAxis(),
                      series: <CartesianSeries>[
                        BarSeries<_ChartData, String>(
                          dataSource: _createSampleData(),
                          xValueMapper: (_ChartData data, _) => data.x,
                          yValueMapper: (_ChartData data, _) => data.y,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'Citas por Tipo',
                    style: TextStyle(fontSize: 24),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 200,
                      maxWidth: !smallView ? 400.0 : size.width,
                    ),
                    child: SfCircularChart(
                      series: <CircularSeries>[
                        PieSeries<_ChartData, String>(
                          dataSource: _createSampleData(),
                          xValueMapper: (_ChartData data, _) => data.x,
                          yValueMapper: (_ChartData data, _) => data.y,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'Pacientes por Semanas de Gestación',
                    style: TextStyle(fontSize: 24),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 200,
                      maxWidth: !smallView ? 400.0 : size.width,
                    ),
                    child: SfCartesianChart(
                      primaryXAxis: const CategoryAxis(),
                      series: <CartesianSeries>[
                        LineSeries<_ChartData, String>(
                          dataSource: _createSampleData(),
                          xValueMapper: (_ChartData data, _) => data.x,
                          yValueMapper: (_ChartData data, _) => data.y,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // const ChartSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class StatisticTile extends StatelessWidget {
  final String title;
  final String value;

  const StatisticTile({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }
}

class ChartSection extends StatelessWidget {
  const ChartSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        const SizedBox(height: 16),
        const Text('Citas por Tipo'),
        SizedBox(
          height: 200,
          child: SfCircularChart(
            series: <CircularSeries>[
              PieSeries<_ChartData, String>(
                dataSource: _createSampleData(),
                xValueMapper: (_ChartData data, _) => data.x,
                yValueMapper: (_ChartData data, _) => data.y,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Pacientes por Semanas de Gestación'),
        SizedBox(
          height: 200,
          child: SfCartesianChart(
            primaryXAxis: const CategoryAxis(),
            series: <CartesianSeries>[
              LineSeries<_ChartData, String>(
                dataSource: _createSampleData(),
                xValueMapper: (_ChartData data, _) => data.x,
                yValueMapper: (_ChartData data, _) => data.y,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static List<_ChartData> _createSampleData() {
    return [
      _ChartData('Doctor A', 30),
      _ChartData('Doctor B', 40),
      _ChartData('Doctor C', 50),
      // Agrega más datos según sea necesario
    ];
  }
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
}
 */
