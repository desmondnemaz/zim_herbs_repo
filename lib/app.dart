import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/core/theme/light_mode.dart';
import 'package:zim_herbs_repo/features/auth/bloc/auth_cubit.dart';
import 'package:zim_herbs_repo/features/auth/data/fake_auth_repository.dart';
import 'package:zim_herbs_repo/features/auth/presentation/auth_gate.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/datasources/herb_remote_datasource.dart';
import 'package:zim_herbs_repo/features/repository/herbs/data/repositories/herb_repository_impl.dart';
import 'package:zim_herbs_repo/features/repository/herbs/presentation/cubit/herb_cubit.dart';
import 'package:zim_herbs_repo/features/settings/bloc/settings_cubit.dart';
import 'package:zim_herbs_repo/features/settings/data/repository/settings_repository.dart';
import 'package:zim_herbs_repo/core/connection/bloc/connection_bloc.dart' as conn;
import 'package:zim_herbs_repo/features/marketplace/store/data/repository/store_repository.dart';
import 'package:zim_herbs_repo/features/marketplace/store/bloc/store_bloc.dart';
import 'package:zim_herbs_repo/features/marketplace/store/bloc/store_event.dart';
import 'package:zim_herbs_repo/features/marketplace/store/bloc/cart_cubit.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final fakeAuthRepo = FakeAuthRepository();

    return MultiBlocProvider(
      providers: [
  BlocProvider(
    create: (context) => AuthCubit(fakeAuthRepo)..checkAuth(),
  ),

  BlocProvider(
    create: (context) =>
        SettingsCubit(SettingsRepository())..loadSettings(),
  ),

  BlocProvider(
    create: (context) =>
        conn.ConnectionBloc()..add(conn.ConnectionListen()),
  ),

  BlocProvider(
    create: (context) =>
        StoreBloc(StoreRepository())..add(FetchProducts()),
  ),
//_____________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________
  
  
  // HERB FEATURE
  BlocProvider(
    create: (context) {
      // 1. Supabase connection
      final client = Supabase.instance.client;

      // 2. Data layer
      final dataSource = HerbRemoteDataSource(client);

      // 3. Data → Domain bridge
      final repository = HerbRepositoryImpl(dataSource);

      // 4. Presentation layer
      return HerbCubit(repository)..loadHerbs();
    },
  ),
//_________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________
  
  BlocProvider(
    create: (context) => CartCubit(),
  ),
],

      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            debugShowCheckedModeBanner: false,
            theme: pharmacyTheme,
            home: BlocListener<conn.ConnectionBloc, conn.ConnectionState>(
              listenWhen:
                  (previous, current) => previous.status != current.status,
              listener: (context, state) {
                if (state.status == conn.ConnectionStatus.offline) {
                  rootScaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.wifi_off, color: Colors.white),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No internet, some features will not work correctly',
                            ),
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
                          rootScaffoldMessengerKey.currentState
                              ?.hideCurrentSnackBar();
                        },
                      ),
                    ),
                  );
                } else if (state.status == conn.ConnectionStatus.online) {
                  rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();
                  rootScaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.wifi, color: Colors.white),
                          SizedBox(width: 12),
                          Text('You are online'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: const AuthGate(),
            ),
          );
        },
      ),
    );
  }
}
