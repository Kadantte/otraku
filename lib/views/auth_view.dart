import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:otraku/views/home_view.dart';
import 'package:otraku/utils/client.dart';
import 'package:otraku/widgets/loaders.dart/loader.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthView extends StatefulWidget {
  static const ROUTE = '/auth';

  const AuthView();

  @override
  _AuthViewState createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  bool _loading = true;

  void _verify() => Client.logIn().then(
        (loggedIn) => loggedIn
            ? Get.offAllNamed(HomeView.ROUTE)
            : setState(() => _loading = false),
      );

  Future<void> _requestAccessToken() async {
    setState(() => _loading = true);

    const redirectUrl =
        'https://anilist.co/api/v2/oauth/authorize?client_id=3535&response_type=token';

    try {
      await launch(redirectUrl);
    } catch (err) {
      Get.defaultDialog(
        radius: 10,
        backgroundColor: Get.theme.backgroundColor,
        titleStyle: Get.theme.textTheme.headline6,
        title: 'Could not open AniList',
        content: Text(err.toString()),
        actions: [TextButton(child: Text('Oh No'), onPressed: Get.back)],
      );
      setState(() => _loading = false);
      return;
    }

    AppLinks(onAppLink: (Uri uri, String str) {
      final link = uri.toString();
      final start = link.indexOf('=') + 1;
      final end = link.indexOf('&');
      Client.setCredentials(
        link.substring(start, end),
        int.parse(link.substring(link.lastIndexOf('=') + 1)),
      );
      closeWebView();
      _verify();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _loading
            ? const Loader()
            : SafeArea(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  padding: const EdgeInsets.only(bottom: 50),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Text(
                          'An unofficial AniList app.',
                          style: Theme.of(context).textTheme.headline1,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Ionicons.log_in_outline),
                        label: Text('Connect to AniList'),
                        onPressed: _requestAccessToken,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _verify();
  }
}
