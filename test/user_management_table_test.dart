import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PaginatedDataTable renders properly with bounded width', (tester) async {
    final sampleUsers = [
      {
        'id': '1',
        'full_name': 'Test User 1',
        'email': 'user1@example.com',
        'is_admin': true,
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'id': '2',
        'full_name': 'Test User 2',
        'email': 'user2@example.com',
        'is_admin': false,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Theme(
              data: ThemeData.light().copyWith(
                cardTheme: CardThemeData(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              child: PaginatedDataTable(
                columns: const [
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Actions')),
                ],
                source: _TestUserSource(sampleUsers),
                rowsPerPage: 10,
                availableRowsPerPage: const [10, 25],
                onRowsPerPageChanged: (val) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Test User 1'), findsOneWidget);
    expect(find.text('user1@example.com'), findsOneWidget);
    expect(find.text('Test User 2'), findsOneWidget);
  });
}

class _TestUserSource extends DataTableSource {
  final List<Map<String, dynamic>> users;
  _TestUserSource(this.users);

  @override
  DataRow? getRow(int index) {
    if (index >= users.length) return null;
    final user = users[index];
    return DataRow(
      cells: [
        DataCell(Text(user['full_name'] as String)),
        DataCell(Text(user['email'] as String)),
        const DataCell(Icon(Icons.more_vert)),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => users.length;
  @override
  int get selectedRowCount => 0;
}
