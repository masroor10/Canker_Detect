/*
import 'package:canker_detect/firebase_options.dart';
import 'package:canker_detect/profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'next_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'constants.dart';
import 'signin_page.dart';
import 'splashscreen.dart'; // import the splashscreen.dart file
import 'onboarding_screen.dart';
import 'package:get/get.dart';
import 'Controller/controller.dart';
import 'Widgets/header_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'WeatherPage.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'Languages.dart';
import 'Controller/language_controller.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp();
  
  runApp( EasyLocalization(
        supportedLocales: [
          Locale('en', 'US'),
          Locale('hi', 'IN'),
          Locale('ur', 'PK'),
          
        ],
        path: 'assets/translations',
        fallbackLocale: Locale('en', 'US'),
    child:  const MyApp()
    ),
    );
    
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
   return MultiProvider (
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageController()),
      ],
      
      child: MaterialApp(
      title: 'Canker Detection',
      
  
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      initialRoute: '/splash', // set the initial route
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/switchlanguagescreen':(context) => SwitchLanguageScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/next_page': (context) => const NextPage(),
        '/login': (context) => SignIn(),
        // '/profile': (context) => ProfilePage(),
      },
     
      
      ),
      
    );
  }
}
*/

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:canker_detect/Languages.dart';
import 'package:canker_detect/onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:canker_detect/Community3/providers/user_providers.dart';
import 'package:canker_detect/Community3/responsive/mobilescreenlayout.dart';
import 'package:canker_detect/Community3/responsive/responsive_layout_screen.dart';
import 'package:canker_detect/Community3/responsive/webscreenlayout.dart';
import 'package:canker_detect/Community3/screens/login_screen.dart';
import 'package:canker_detect/Community3/screens/signupscreen.dart';
import 'package:canker_detect/utils/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:canker_detect/SplashScreen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'Controller/language_controller.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:canker_detect/languagescreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp();
  runApp( EasyLocalization(
      supportedLocales: [
        Locale('en', 'US'),
        Locale('hi', 'IN'),
        Locale('ur', 'PK'),

      ],
      path: 'assets/translations',
      fallbackLocale: Locale('en', 'US'),
      child:  const MyApp2()
  ),
  );



}

class MyApp2 extends StatelessWidget {
  const MyApp2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider(),

        ),
        ChangeNotifierProvider(
          create: (_) => LanguageController(),

        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CankerDetect',
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        theme: ThemeData.light().copyWith(scaffoldBackgroundColor: mobileBackgroundColor),
        home: FutureBuilder(
          // Simulate a delay using Future.delayed.
          future: Future.delayed(Duration(seconds: 3), () {}),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Show the splash screen while waiting.
              return SplashScreen();
            } else if (snapshot.hasError) {
              return Center(child: Text("${snapshot.error}"));
            } else {
              // After the delay, check the user's authentication status.
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                return ResponsiveLayout(
                  mobilescreenlayout: MobileScreenLayout(),
                  webscreenlayout: WebScreenLayout(),
                );
              } else {
                return SwitchLanguageScreen();
              }
            }
          },
        ),
      ),
    );
  }
}

/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp2());
}

class MyApp2 extends StatelessWidget {
  const MyApp2({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        )
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'CankerDetect',
        theme: ThemeData.light()
            .copyWith(scaffoldBackgroundColor: mobileBackgroundColor),
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData) {
                return ResponsiveLayout(
                    mobilescreenlayout: MobileScreenLayout(),
                    webscreenlayout: WebScreenLayout());
              } else if (snapshot.hasError) {
                return Center(child: Text("${snapshot.error}"));
              }
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return LoginScreen();
          },
        ),
        // home: ResponsiveLayout(mobilescreenlayout: MobileScreenLayout(), webscreenlayout:WebScreenLayout() ),
      ),
    );
  }
}*/
