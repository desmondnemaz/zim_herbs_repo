import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/config/supabase_config.dart';
import 'package:zim_herbs_repo/features/dashboard/presentation/home_page.dart';
import 'package:zim_herbs_repo/theme/light_mode.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zim_herbs_repo/features/settings/bloc/settings_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/connection/bloc/connection_bloc.dart'
    as conn;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SettingsBloc()..add(LoadSettings())),
        BlocProvider(
          create:
              (context) => conn.ConnectionBloc()..add(conn.ConnectionListen()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: pharmacyTheme,
            home: BlocListener<conn.ConnectionBloc, conn.ConnectionState>(
              listenWhen:
                  (previous, current) => previous.status != current.status,
              listener: (context, state) {
                if (state.status == conn.ConnectionStatus.offline) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.wifi_off, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'No internet, some features will not work correctly',
                          ),
                        ],
                      ),
                      backgroundColor: Colors.redAccent,
                      duration: const Duration(
                        days: 1,
                      ), // Persistent until dismissed or online
                      action: SnackBarAction(
                        label: 'DISMISS',
                        textColor: Colors.white,
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      ),
                    ),
                  );
                } else if (state.status == conn.ConnectionStatus.online) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.wifi, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Back Online'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: const HomePage(),
            ),
          );
        },
      ),
    );
  }
}
