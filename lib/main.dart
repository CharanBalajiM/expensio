import 'package:expensio/blocs/expense/expense_bloc.dart';
import 'package:expensio/blocs/savings/savings_bloc.dart';
import 'package:expensio/screen/main_navigation_screen.dart';
import 'package:expensio/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ExpenseBloc>(create: (context) => ExpenseBloc()),
        BlocProvider<SavingsBloc>(create: (context) => SavingsBloc()),
      ],
      child: MaterialApp(
        title: 'Expensio',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF09090B),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00E676),
            surface: Color(0xFF141416),
            onSurface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF09090B),
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        home: const MainNavigationScreen(),
      ),
    );
  }
}
