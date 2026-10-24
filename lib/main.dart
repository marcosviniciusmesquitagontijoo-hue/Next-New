import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

const String serverBase = 'http://wanvistorenv.top';
const bg = Color(0xFF101010);
const panel = Color(0xFF242424);
const fieldBg = Color(0xFF1C1C1C);
const accent = Color(0xFF713BC1);
const accentLight = Color(0xFFB45AF0);

void main() => runApp(const NextApp());

class NextApp extends StatelessWidget {
  const NextApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Next IPTV',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
      useMaterial3: true,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: Colors.white, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldBg,
        hintStyle: const TextStyle(color: Color(0xFF777783), fontSize: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: accent, width: 2)),
      ),
    ),
    home: const LoginPage(),
  );
}

class XtreamApi {
  final String username;
  final String password;
  XtreamApi(this.username, this.password);

  Uri _uri([Map<String, String>? extra]) => Uri.parse('$serverBase/player_api.php').replace(
    queryParameters: {'username': username, 'password': password, ...?extra},
  );

  Future<Map<String, dynamic>> login() async {
    final r = await http.get(_uri()).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) throw Exception('Servidor respondeu HTTP ${r.statusCode}.');
    final data = jsonDecode(r.body);
    if (data is! Map<String, dynamic> || data['user_info'] == null) throw Exception('Resposta do servidor não reconhecida.');
    final info = data['user_info'];
    if (info is Map && (info['auth'] == 0 || info['status'] == 'Disabled')) throw Exception('Usuário ou senha inválidos, ou acesso desativado.');
    return data;
  }

  Future<List<dynamic>> getList(String action) async {
    final r = await http.get(_uri({'action': action})).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) throw Exception('Falha ao carregar catálogo (${r.statusCode}).');
    final data = jsonDecode(r.body);
    return data is List ? data : <dynamic>[];
  }

  Future<Map<String, dynamic>> getSeriesInfo(String id) async {
    final r = await http.get(_uri({'action': 'get_series_info', 'series_id': id})).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) throw Exception('Falha ao carregar episódios.');
    final data = jsonDecode(r.body);
    if (data is! Map<String, dynamic>) throw Exception('Resposta de série inválida.');
    return data;
  }

  String streamUrl(String type, dynamic item) {
    final id = '${item['stream_id'] ?? item['series_id'] ?? item['id'] ?? ''}';
    final ext = '${item['container_extension'] ?? (type == 'live' ? 'ts' : 'mp4')}';
    if (type == 'live') return '$serverBase/live/$username/$password/$id.ts';
    if (type == 'movie') return '$serverBase/movie/$username/$password/$id.$ext';
    return '$serverBase/series/$username/$password/$id.$ext';
  }
}

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 74});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accentLight, accent, Color(0xFF48228B)]),
      borderRadius: BorderRadius.circular(size * .27),
      boxShadow: [BoxShadow(color: accent.withOpacity(.35), blurRadius: 24, spreadRadius: 1)],
    ),
    child: Icon(Icons.play_arrow_rounded, size: size * .76, color: Colors.white),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();
  final userFocus = FocusNode();
  final passFocus = FocusNode();
  final enterFocus = FocusNode();
  bool loading = false, obscure = true;
  String? error;

  Future<void> enter() async {
    if (user.text.trim().isEmpty || pass.text.isEmpty) {
      setState(() => error = 'Informe seu usuário e sua senha.');
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      final api = XtreamApi(user.text.trim(), pass.text);
      final account = await api.login();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomePage(api: api, account: account)));
    } catch (_) {
      if (mounted) setState(() => error = 'Não foi possível entrar. Confira os dados e a conexão.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() { user.dispose(); pass.dispose(); userFocus.dispose(); passFocus.dispose(); enterFocus.dispose(); super.dispose(); }

  Widget loginForm({required bool wide}) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 520),
    child: Container(
      padding: EdgeInsets.all(wide ? 38 : 26),
      decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(wide ? 30 : 24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(.28), blurRadius: 32, offset: const Offset(0, 14))]),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Entrar', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 28),
        TextField(
          controller: user, focusNode: userFocus, textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          onSubmitted: (_) => passFocus.requestFocus(),
          decoration: const InputDecoration(hintText: 'Usuário', suffixIcon: Icon(Icons.person, color: accentLight, size: 25)),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: pass, focusNode: passFocus, obscureText: obscure, textInputAction: TextInputAction.done,
          onSubmitted: (_) => enter(),
          decoration: InputDecoration(hintText: 'Senha', suffixIcon: IconButton(
            tooltip: obscure ? 'Mostrar senha' : 'Ocultar senha',
            icon: Icon(obscure ? Icons.lock : Icons.lock_open, color: accentLight, size: 24),
            onPressed: () => setState(() => obscure = !obscure),
          )),
        ),
        if (error != null) ...[
          const SizedBox(height: 14),
          Text(error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        SizedBox(height: 58, child: Focus(
          focusNode: enterFocus,
          child: Builder(builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8), border: Border.all(color: focused ? Colors.white : accent, width: focused ? 3 : 1)),
              child: TextButton(
                autofocus: true,
                onPressed: loading ? null : enter,
                style: TextButton.styleFrom(foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: loading ? const SizedBox(width: 23, height: 23, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Entrar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              ),
            );
          }),
        )),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 850;
      if (wide) {
        return Row(children: [
          Expanded(flex: 5, child: Container(
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF17131E), Color(0xFF0C0C0E)])),
            child: Stack(fit: StackFit.expand, children: [
              Opacity(opacity: .09, child: Image.network('https://image.tmdb.org/t/p/w1280/8b8R8l88Qje9dn9OE8PY05NeklB.jpg', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
              Center(child: Column(mainAxisSize: MainAxisSize.min, children: [BrandMark(size: 112), const SizedBox(height: 22), const Text('NEXT', style: TextStyle(fontSize: 43, fontWeight: FontWeight.w900, letterSpacing: 7)), const SizedBox(height: 8), const Text('Seu entretenimento em um só lugar', style: TextStyle(color: Colors.white60, fontSize: 16))])),
            ]),
          )),
          Expanded(flex: 7, child: Container(color: const Color(0xFF171717), child: Center(child: Padding(padding: const EdgeInsets.all(36), child: loginForm(wide: true))))),
        ]);
      }
      return Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF17121F), bg])),
        child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const BrandMark(size: 76), const SizedBox(height: 14), const Text('NEXT', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900, letterSpacing: 5)),
          const SizedBox(height: 28), loginForm(wide: false),
        ]))),
      );
    })),
  );
}

class HomePage extends StatefulWidget {
  final XtreamApi api;
  final Map<String, dynamic> account;
  const HomePage({super.key, required this.api, required this.account});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;
  late Future<List<dynamic>> content;
  final actions = ['get_live_streams', 'get_vod_streams', 'get_series'];
  final titles = ['Canais ao vivo', 'Filmes', 'Séries'];
  final types = ['live', 'movie', 'series'];
  final search = TextEditingController();
  String query = '';

  @override
  void initState() { super.initState(); content = widget.api.getList(actions[0]); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  void changeTab(int index) {
    if (index < 0 || index >= actions.length) return;
    setState(() { tab = index; content = widget.api.getList(actions[index]); query = ''; search.clear(); });
  }

  Widget navItem(int index, IconData icon, String label, {bool compact = false}) {
    final selected = tab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(color: selected ? accent.withOpacity(.24) : Colors.transparent, borderRadius: BorderRadius.circular(12), child: InkWell(
        borderRadius: BorderRadius.circular(12), focusColor: accent.withOpacity(.55), onTap: () => changeTab(index),
        child: Container(padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: 14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: selected ? accent : Colors.transparent, width: 1.5)), child: Row(mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max, children: [Icon(icon, color: selected ? accentLight : Colors.white60, size: 23), if (!compact) ...[const SizedBox(width: 13), Expanded(child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.white70, fontWeight: selected ? FontWeight.bold : FontWeight.normal)))]])),
      )),
    );
  }

  Widget contentCard(Map<String, dynamic> item, int index, double width) {
    final name = '${item['name'] ?? 'Sem título'}';
    final image = '${item['stream_icon'] ?? item['cover'] ?? item['stream_icon'] ?? ''}';
    return SizedBox(width: width, child: FocusableActionDetector(
      shortcuts: const <ShortcutActivator, Intent>{SingleActivator(LogicalKeyboardKey.select): ActivateIntent(), SingleActivator(LogicalKeyboardKey.enter): ActivateIntent()},
      actions: <Type, Action<Intent>>{ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) { openItem(item, name); return null; })},
      child: Builder(builder: (context) {
        final focused = Focus.of(context).hasFocus;
        return AnimatedContainer(duration: const Duration(milliseconds: 120), decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: focused ? accentLight : Colors.white10, width: focused ? 3 : 1), boxShadow: focused ? [BoxShadow(color: accent.withOpacity(.35), blurRadius: 15)] : []), child: InkWell(
          autofocus: index == 0 && tab == 0,
          focusColor: accent.withOpacity(.22), borderRadius: BorderRadius.circular(12), onTap: () => openItem(item, name),
          child: ClipRRect(borderRadius: BorderRadius.circular(11), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: Stack(fit: StackFit.expand, children: [
              if (image.startsWith('http')) Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.movie_outlined, size: 38, color: Colors.white24))) else const Center(child: Icon(Icons.movie_outlined, size: 38, color: Colors.white24)),
              if (tab == 0) Container(color: Colors.black.withOpacity(.16), child: const Center(child: Icon(Icons.play_circle_outline, size: 42, color: Colors.white))),
            ])),
            Padding(padding: const EdgeInsets.all(9), child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          ])),
        ));
      }),
    ));
  }

  void openItem(Map<String, dynamic> item, String name) {
    if (tab == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesPage(api: widget.api, series: item)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(title: name, url: widget.api.streamUrl(types[tab], item))));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(children: [BrandMark(size: 34), SizedBox(width: 10), Text('NEXT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3))]),
      actions: [IconButton(tooltip: 'Atualizar catálogo', onPressed: () => setState(() => content = widget.api.getList(actions[tab])), icon: const Icon(Icons.refresh)), const SizedBox(width: 8)],
    ),
    body: LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 850;
      final tv = constraints.maxWidth >= 1100;
      final side = wide ? SizedBox(width: tv ? 235 : 190, child: Padding(padding: const EdgeInsets.fromLTRB(14, 10, 12, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Padding(padding: EdgeInsets.fromLTRB(12, 12, 12, 18), child: Text('MENU PRINCIPAL', style: TextStyle(fontSize: 11, color: Colors.white38, letterSpacing: 1.5, fontWeight: FontWeight.bold))),
        navItem(0, Icons.live_tv_outlined, 'Ao vivo'), navItem(1, Icons.movie_outlined, 'Filmes'), navItem(2, Icons.video_library_outlined, 'Séries'),
        const Spacer(), const Padding(padding: EdgeInsets.all(12), child: Text('NEXT IPTV', style: TextStyle(color: Colors.white30, fontSize: 11, letterSpacing: 1.5))),
      ]))) : null;
      return Row(children: [
        if (side != null) side,
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: EdgeInsets.fromLTRB(wide ? 24 : 18, 12, wide ? 24 : 18, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Olá!', style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 14)),
            Text(titles[tab], style: TextStyle(fontSize: tv ? 32 : 27, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5), const Text('Escolha o que deseja assistir', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 16),
            SizedBox(height: 48, child: TextField(controller: search, onChanged: (v) => setState(() => query = v.trim().toLowerCase()), decoration: const InputDecoration(hintText: 'Buscar conteúdo...', prefixIcon: Icon(Icons.search), contentPadding: EdgeInsets.symmetric(vertical: 10)))),
          ])),
          Expanded(child: FutureBuilder<List<dynamic>>(future: content, builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: accentLight));
            if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Não foi possível carregar o catálogo.\nVerifique a conexão e tente atualizar.', textAlign: TextAlign.center)));
            final items = (snap.data ?? []).where((e) => e is Map && '${e['name'] ?? ''}'.toLowerCase().contains(query)).toList();
            if (items.isEmpty) return const Center(child: Text('Nenhum conteúdo encontrado.'));
            final posterWidth = tv ? 155.0 : (wide ? 135.0 : 112.0);
            return GridView.builder(
              padding: EdgeInsets.fromLTRB(wide ? 24 : 18, 0, wide ? 24 : 18, 24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (constraints.maxWidth / (posterWidth + 16)).floor().clamp(2, tv ? 8 : (wide ? 6 : 3)),
                childAspectRatio: tab == 0 ? 0.95 : 0.62,
                crossAxisSpacing: 13, mainAxisSpacing: 14,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => contentCard(items[i] as Map<String, dynamic>, i, double.infinity),
            );
          })),
        ])),
      ]);
    }),
    bottomNavigationBar: MediaQuery.of(context).size.width < 850 ? NavigationBar(
      backgroundColor: panel, indicatorColor: accent.withOpacity(.25), selectedIndex: tab, onDestinationSelected: changeTab,
      destinations: const [NavigationDestination(icon: Icon(Icons.live_tv_outlined), selectedIcon: Icon(Icons.live_tv), label: 'Ao vivo'), NavigationDestination(icon: Icon(Icons.movie_outlined), selectedIcon: Icon(Icons.movie), label: 'Filmes'), NavigationDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library), label: 'Séries')],
    ) : null,
  );
}

class SeriesPage extends StatefulWidget {
  final XtreamApi api;
  final Map<String, dynamic> series;
  const SeriesPage({super.key, required this.api, required this.series});
  @override
  State<SeriesPage> createState() => _SeriesPageState();
}

class _SeriesPageState extends State<SeriesPage> {
  late Future<Map<String, dynamic>> info;
  @override
  void initState() { super.initState(); info = widget.api.getSeriesInfo('${widget.series['series_id'] ?? widget.series['id'] ?? ''}'); }

  @override
  Widget build(BuildContext context) {
    final title = '${widget.series['name'] ?? 'Série'}';
    return Scaffold(appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)), body: FutureBuilder<Map<String, dynamic>>(future: info, builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: accentLight));
      if (snap.hasError) return const Center(child: Text('Não foi possível carregar os episódios desta série.'));
      final episodes = snap.data?['episodes'];
      if (episodes is! Map || episodes.isEmpty) return const Center(child: Text('Nenhum episódio disponível.'));
      final seasons = episodes.keys.toList()..sort((a, b) => '$a'.compareTo('$b'));
      return ListView(padding: const EdgeInsets.all(18), children: [Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)), for (final season in seasons) ...[
        Padding(padding: const EdgeInsets.only(top: 20, bottom: 8), child: Text('Temporada $season', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
        if (episodes[season] is List) for (final ep in episodes[season] as List) Card(color: panel, child: ListTile(autofocus: false, leading: const Icon(Icons.play_circle_outline, color: accentLight, size: 32), title: Text('${ep['title'] ?? ep['name'] ?? 'Episódio'}'), subtitle: Text('Episódio ${ep['episode_num'] ?? ''}'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(title: '${ep['title'] ?? ep['name'] ?? title}', url: widget.api.streamUrl('series', ep))))),
      ]]);
    }));
  }
}

class PlayerPage extends StatefulWidget {
  final String title, url;
  const PlayerPage({super.key, required this.title, required this.url});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? controller;
  String? error;
  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    controller!.initialize().then((_) { if (mounted) setState(() {}); controller?.play(); }).catchError((_) { if (mounted) setState(() => error = 'Não foi possível reproduzir este conteúdo.'); });
  }
  @override
  void dispose() { controller?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
    body: Center(child: error != null ? Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center)) : controller == null || !controller!.value.isInitialized ? const CircularProgressIndicator(color: accentLight) : AspectRatio(aspectRatio: controller!.value.aspectRatio, child: VideoPlayer(controller!))),
    floatingActionButton: controller != null && controller!.value.isInitialized ? FloatingActionButton(backgroundColor: accent, onPressed: () => controller!.value.isPlaying ? controller!.pause() : controller!.play(), child: Icon(controller!.value.isPlaying ? Icons.pause : Icons.play_arrow)) : null,
  );
}
