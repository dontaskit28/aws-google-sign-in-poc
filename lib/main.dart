import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _amplifyConfigured = false;
  String _userInfo = 'Not signed in';
  String _tokenInfo = '';

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      final authPlugin = AmplifyAuthCognito();
      await Amplify.addPlugin(authPlugin);
      await Amplify.configure(amplifyconfig);
      setState(() {
        _amplifyConfigured = true;
      });

      // Check if already signed in
      await _checkAuthStatus();
    } on Exception catch (e) {
      safePrint('Error configuring Amplify: $e');
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      if (session.isSignedIn) {
        await _fetchTokens();
        await _getCurrentUser();
      }
    } catch (e) {
      safePrint('Not signed in: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final result = await Amplify.Auth.signInWithWebUI(
        provider: AuthProvider.google,
      );
      safePrint('Sign in result: $result');

      if (result.isSignedIn) {
        await _fetchTokens();
        await _getCurrentUser();
      }
    } on AuthException catch (e) {
      safePrint('Error signing in: ${e.message}');
    }
  }

  // Fetch authentication tokens
  Future<void> _fetchTokens() async {
    try {
      final session =
          await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;

      if (session.isSignedIn) {
        // Get the tokens
        final idToken = session.userPoolTokensResult.value.idToken.raw;
        final accessToken = session.userPoolTokensResult.value.accessToken.raw;
        final refreshToken = session.userPoolTokensResult.value.refreshToken;

        setState(() {
          _tokenInfo = '''
              🔐 TOKENS RETRIEVED:
              🆔 ID Token: ${idToken.toString().substring(0, 50)}...
              🔑 Access Token: ${accessToken.toString().substring(0, 50)}...
              🔄 Refresh Token: ${refreshToken.toString().substring(0, 50)}...
              ✅ Session Status: ${session.isSignedIn ? 'Signed In' : 'Not Signed In'}
          ''';
        });

        safePrint('ID Token: $idToken');
        safePrint('Access Token: $accessToken');
        safePrint('Refresh Token: $refreshToken');
      }
    } on AuthException catch (e) {
      safePrint('Error fetching tokens: ${e.message}');
      setState(() {
        _tokenInfo = 'Error fetching tokens: ${e.message}';
      });
    }
  }

  // Get current user information
  Future<void> _getCurrentUser() async {
    try {
      final user = await Amplify.Auth.getCurrentUser();
      setState(() {
        _userInfo = 'User ID: ${user.userId}\nUsername: ${user.username}';
      });
    } on AuthException catch (e) {
      setState(() {
        _userInfo = 'Error getting user: ${e.message}';
      });
    }
  }

  // Force refresh tokens (useful when tokens are about to expire)
  Future<void> _refreshTokens() async {
    try {
      final session =
          await Amplify.Auth.fetchAuthSession(
                options: const FetchAuthSessionOptions(forceRefresh: true),
              )
              as CognitoAuthSession;

      if (session.isSignedIn) {
        await _fetchTokens();
        safePrint('Tokens refreshed successfully');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tokens refreshed successfully!')),
        );
      }
    } on AuthException catch (e) {
      safePrint('Error refreshing tokens: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing tokens: ${e.message}')),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut();
      setState(() {
        _userInfo = 'Not signed in';
        _tokenInfo = '';
      });
      safePrint('Signed out');
    } on AuthException catch (e) {
      safePrint('Error signing out: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AWS Google Sign-In Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text("Google Sign-In with AWS")),
        body:
            _amplifyConfigured
                ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // User Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User Information:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(_userInfo),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tokens Info Card
                      if (_tokenInfo.isNotEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Authentication Tokens:',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _tokenInfo,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(Icons.login),
                        label: const Text("Sign in with Google"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed: _fetchTokens,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Fetch Current Tokens"),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed: _refreshTokens,
                        icon: const Icon(Icons.autorenew),
                        label: const Text("Force Refresh Tokens"),
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text("Sign out"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
                : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
