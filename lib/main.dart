import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zim_herbs_repo/config/supabase_config.dart';
import 'package:zim_herbs_repo/features/onboarding/presentation/splash_page.dart';
import 'package:zim_herbs_repo/theme/light_mode.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zim_herbs_repo/features/settings/bloc/settings_cubit.dart';
import 'package:zim_herbs_repo/features/settings/data/repository/settings_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zim_herbs_repo/core/connection/bloc/connection_bloc.dart'
    as conn;
import 'package:zim_herbs_repo/features/store/data/repository/store_repository.dart';
import 'package:zim_herbs_repo/features/store/bloc/store_bloc.dart';
import 'package:zim_herbs_repo/features/store/bloc/store_event.dart';
import 'package:zim_herbs_repo/features/store/bloc/cart_cubit.dart';
import 'package:zim_herbs_repo/features/herbs/bloc/herb_bloc.dart';
import 'package:zim_herbs_repo/features/herbs/data/herb_repository.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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
        BlocProvider(
          create:
              (context) => SettingsCubit(SettingsRepository())..loadSettings(),
        ),
        BlocProvider(
          create:
              (context) => conn.ConnectionBloc()..add(conn.ConnectionListen()),
        ),
        BlocProvider(
          create:
              (context) => StoreBloc(StoreRepository())..add(FetchProducts()),
        ),
        BlocProvider(
          create: (context) => HerbBloc(HerbRepository()),
        ),
        BlocProvider(create: (context) => CartCubit()),
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
              child: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
