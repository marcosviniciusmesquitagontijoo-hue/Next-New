import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

const String serverBase = 'http://wanvistorenv.top';

void main() => runApp(const NextApp());

const bg = Color(0xFF090D16);
const panel = Color(0xFF141B2A);
const accent = Color(0xFF2D7DFF);

class NextApp extends StatelessWidget {
  const NextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Next IPTV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: panel,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      home: const LoginPage(),
    );
  }
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
    if (data is! Map<String, dynamic> || data['user_info'] == null) {
      throw Exception('Resposta do servidor não reconhecida.');
    }
    final info = data['user_info'];
    if (info is Map && (info['auth'] == 0 || info['status'] == 'Disabled')) {
      throw Exception('Usuário ou senha inválidos, ou acesso desativado.');
    }
    return data;
  }

  Future<List<dynamic>> getList(String action) async {
    final r = await http.get(_uri({'action': action})).timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) throw Exception('Falha ao carregar catálogo (${r.statusCode}).');
    final data = jsonDecode(r.body);
    return data is List ? data : <dynamic>[];
  }

  Future<Map<String, dynamic>> getSeriesInfo(String id) async {
    final r = await http.get(_uri({'action': 'get_series_info', 'series_id': id}))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) throw Exception('Falha ao carregar episódios.');
    final data = jsonDecode(r.body);
    if (data is! Map<String, dynamic>) throw Exception('Resposta de série inválida.');
    return data;
  }

  String streamUrl(String type, dynamic item) {
    final id = '${item['stream_id'] ?? item['series_id'] ?? item['id'] ?? ''}';
    final ext = '${item['container_extension'] ?? 'mp4'}';
    if (type == 'live') return '$serverBase/live/$username/$password/$id.ts';
    if (type == 'movie') return '$serverBase/movie/$username/$password/$id.$ext';
    return '$serverBase/series/$username/$password/$id.$ext';
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final user = TextEditingController();
  final pass = TextEditingController();
  bool loading = false, obscure = true;
  String? error;

  Future<void> enter() async {
    if (user.text.trim().isEmpty || pass.text.isEmpty) {
      setState(() => error = 'Informe usuário e senha.');
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      final api = XtreamApi(user.text.trim(), pass.text);
      final account = await api.login();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => HomePage(api: api, account: account),
      ));
    } catch (e) {
      setState(() => error = 'Não foi possível entrar. Confira os dados e a conexão com o servidor.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() { user.dispose(); pass.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(26),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SizedBox(height: 26),
              Container(
                width: 84, height: 84, alignment: Alignment.center,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [accent, Color(0xFF53C8FF)]), borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.play_arrow_rounded, size: 54, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('NEXT', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 5)),
              const SizedBox(height: 6),
              const Text('Seu entretenimento em um só lugar', style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 34),
              TextField(controller: user, textInputAction: TextInputAction.next, autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline), labelText: 'Usuário')),
              const SizedBox(height: 14),
              TextField(controller: pass, obscureText: obscure, onSubmitted: (_) => enter(),
                decoration: InputDecoration(prefixIcon: const Icon(Icons.lock_outline), labelText: 'Senha',
                  suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => obscure = !obscure)))),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 22),
              SizedBox(height: 52, child: FilledButton(
                onPressed: loading ? null : enter,
                child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('ENTRAR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              )),
              const SizedBox(height: 22),
              const Text('Acesso com conta Xtream Codes', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
          ),
        ),
      ),
    ),
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

  @override
  void initState() { super.initState(); content = widget.api.getList(actions[0]); }

  void changeTab(int index) {
    setState(() { tab = index; content = widget.api.getList(actions[index]); });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(children: [Icon(Icons.play_circle_fill, color: accent), SizedBox(width: 9), Text('NEXT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2))]),
      actions: [IconButton(tooltip: 'Atualizar', onPressed: () => setState(() => content = widget.api.getList(actions[tab])), icon: const Icon(Icons.refresh))],
    ),
    body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Olá!', style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 14)),
          Text(titles[tab], style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Escolha o que deseja assistir', style: TextStyle(color: Colors.white54)),
        ])),
      Expanded(child: FutureBuilder<List<dynamic>>(
        future: content,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Não foi possível carregar o catálogo.\nVerifique o servidor e tente atualizar.', textAlign: TextAlign.center)));
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Nenhum conteúdo encontrado.'));
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
              childAspectRatio: tab == 0 ? 1.5 : .68,
              crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i] as Map<String, dynamic>;
              final name = '${item['name'] ?? 'Sem título'}';
              final image = '${item['stream_icon'] ?? item['cover'] ?? ''}';
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  if (tab == 2) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => SeriesPage(api: widget.api, series: item)));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(
                      title: name, url: widget.api.streamUrl(types[tab], item))));
                  }
                },
                child: Container(
                  decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(child: Stack(fit: StackFit.expand, children: [
                      if (image.startsWith('http')) Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.movie_outlined, size: 42, color: Colors.white24))
                      else const Center(child: Icon(Icons.movie_outlined, size: 42, color: Colors.white24)),
                      if (tab == 0) const Align(alignment: Alignment.center, child: Icon(Icons.play_circle_outline, size: 42, color: Colors.white70)),
                    ])),
                    Padding(padding: const EdgeInsets.all(10), child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ]),
                ),
              );
            },
          );
        },
      )),
    ]),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: changeTab,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.live_tv_outlined), selectedIcon: Icon(Icons.live_tv), label: 'Ao vivo'),
        NavigationDestination(icon: Icon(Icons.movie_outlined), selectedIcon: Icon(Icons.movie), label: 'Filmes'),
        NavigationDestination(icon: Icon(Icons.video_library_outlined), selectedIcon: Icon(Icons.video_library), label: 'Séries'),
      ],
    ),
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
  void initState() {
    super.initState();
    info = widget.api.getSeriesInfo('${widget.series['series_id'] ?? widget.series['id'] ?? ''}');
  }

  @override
  Widget build(BuildContext context) {
    final title = '${widget.series['name'] ?? 'Série'}';
    return Scaffold(
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: info,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return const Center(child: Text('Não foi possível carregar os episódios desta série.'));
          final episodes = snap.data?['episodes'];
          if (episodes is! Map || episodes.isEmpty) return const Center(child: Text('Nenhum episódio disponível.'));
          final seasonKeys = episodes.keys.toList()..sort((a, b) => '$a'.compareTo('$b'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              for (final season in seasonKeys) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Text('Temporada $season', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                if (episodes[season] is List)
                  for (final ep in episodes[season] as List)
                    Card(
                      color: panel,
                      child: ListTile(
                        leading: const Icon(Icons.play_circle_outline, color: accent, size: 32),
                        title: Text('${ep['title'] ?? ep['name'] ?? 'Episódio'}'),
                        subtitle: Text('Episódio ${ep['episode_num'] ?? ''}'),
                        onTap: () {
                          final url = widget.api.streamUrl('series', ep);
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PlayerPage(title: '${ep['title'] ?? ep['name'] ?? title}', url: url),
                          ));
                        },
                      ),
                    ),
              ],
            ],
          );
        },
      ),
    );
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
    controller!.addListener(() { if (mounted) setState(() {}); });
    controller!.initialize().then((_) {
      if (mounted) setState(() {});
      controller?.play();
    }).catchError((_) {
      if (mounted) setState(() => error = 'Não foi possível reproduzir este conteúdo.');
    });
  }

  @override
  void dispose() { controller?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
    body: Center(child: error != null
      ? Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center))
      : controller == null || !controller!.value.isInitialized
        ? const CircularProgressIndicator()
        : AspectRatio(aspectRatio: controller!.value.aspectRatio, child: VideoPlayer(controller!))),
    floatingActionButton: controller != null && controller!.value.isInitialized
      ? FloatingActionButton(onPressed: () => controller!.value.isPlaying ? controller!.pause() : controller!.play(),
          child: Icon(controller!.value.isPlaying ? Icons.pause : Icons.play_arrow))
      : null,
  );
}
