import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:manny_ui/manny_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const MannyShowcaseApp(),
    ),
  );
}

class MannyShowcaseApp extends StatefulWidget {
  const MannyShowcaseApp({super.key});

  static MannyShowcaseAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MannyShowcaseAppState>()!;

  @override
  State<MannyShowcaseApp> createState() => MannyShowcaseAppState();
}

class MannyShowcaseAppState extends State<MannyShowcaseApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  // ── HUD Theme Palette ──
  static final _lightTheme = MannyTheme.lightTheme.copyWith(
    colorScheme: MannyTheme.lightTheme.colorScheme.copyWith(
      primary: const Color(0xFF059669),
      secondary: const Color(0xFF2563EB),
      tertiary: const Color(0xFFD97706),
      error: const Color(0xFFDC2626),
      surface: const Color(0xFFF4F6F8),
      primaryContainer: const Color(0xFFD1FAE5),
      secondaryContainer: const Color(0xFFDBEAFE),
    ),
    scaffoldBackgroundColor: const Color(0xFFF4F6F8),
    splashFactory: FrostedInkSplash.splashFactory,
  );

  static final _darkTheme = MannyTheme.darkTheme.copyWith(
    colorScheme: MannyTheme.darkTheme.colorScheme.copyWith(
      primary: const Color(0xFF6EE7B7),
      secondary: const Color(0xFF60A5FA),
      tertiary: const Color(0xFFFBBF24),
      error: const Color(0xFFF87171),
      surface: const Color(0xFF0C0F14),
      primaryContainer: const Color(0xFF14332A),
      secondaryContainer: const Color(0xFF1A2740),
    ),
    scaffoldBackgroundColor: const Color(0xFF0C0F14),
    splashFactory: FrostedInkSplash.splashFactory,
  );

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MannyConfig(
      neumorphic: false,
      child: MaterialApp(
        title: 'Manny UI Showcase',
        debugShowCheckedModeBanner: false,
        theme: _lightTheme,
        darkTheme: _darkTheme,
        themeMode: _themeMode,
        scrollBehavior: MannyScrollBehavior().copyWith(
          physics: const ClampingScrollPhysics(),
        ),
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
        home: const ShowcaseShell(),
      ),
    );
  }
}

// ─── Shell ───────────────────────────────────────────────────────────────────

class ShowcaseShell extends StatefulWidget {
  const ShowcaseShell({super.key});

  @override
  State<ShowcaseShell> createState() => _ShowcaseShellState();
}

class _ShowcaseShellState extends State<ShowcaseShell> {
  int _currentPage = 0;
  final _scrollController = ScrollController();
  late final HideOnScrollController _hideController;
  final _navToast = NavToastController();
  bool _navVisible = true;

  @override
  void initState() {
    super.initState();
    _hideController = HideOnScrollController(_scrollController);
    _hideController.addListener(() {
      if (mounted) setState(() => _navVisible = _hideController.visible);
    });
    _navToast.scrollController = _hideController;
    // Wire the global nav toast so NotificationToast.show(useNav: true) works
    NotificationToast.navToastController = _navToast;
  }

  @override
  void dispose() {
    _hideController.dispose();
    _navToast.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final pages = [
      _DashboardPage(scrollController: _scrollController),
      _ComponentsPage(scrollController: _scrollController),
      _ModalsPage(scrollController: _scrollController),
      _FeedbackPage(scrollController: _scrollController),
    ];

    final isMobileNav = context.isMobile;

    final navItems = [
      ItemNavigationView(
        iconBefore: Icon(IconlyBroken.home,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        iconAfter: Icon(IconlyBold.home, color: primaryColor),
        tooltip: 'Dashboard',
      ),
      ItemNavigationView(
        iconBefore: Icon(IconlyBroken.category,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        iconAfter: Icon(IconlyBold.category, color: primaryColor),
        tooltip: 'Components',
      ),
      ItemNavigationView(
        iconBefore: Icon(IconlyBroken.paper,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        iconAfter: Icon(IconlyBold.paper, color: primaryColor),
        tooltip: 'Modals',
      ),
      ItemNavigationView(
        iconBefore: Icon(IconlyBroken.notification,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        iconAfter: Icon(IconlyBold.notification, color: primaryColor),
        tooltip: 'Feedback',
      ),
    ];

    // Mobile: bottom floating navbar
    if (isMobileNav) {
      return Scaffold(
        extendBody: true,
        body: pages[_currentPage],
        bottomNavigationBar: NavigationView(
          useTooltip: false,
          floating: true,
          floatingWidthFactor: 0.88,
          floatingMarginBottom: 18,
          visible: _navVisible,
          toastController: _navToast,
          onChangePage: (i) => setState(() => _currentPage = i),
          selectedIndex: _currentPage,
          curve: Curves.fastLinearToSlowEaseIn,
          durationAnimation: const Duration(milliseconds: 500),
          backgroundColor: theme.scaffoldBackgroundColor,
          color: primaryColor,
          enableGlassmorphism: true,
          items: navItems,
        ),
      );
    }

    // Tablet+: vertical floating pill overlaying content on the left
    return Scaffold(
      body: Stack(
        children: [
          // Full-width content — fills the entire screen
          Positioned.fill(child: pages[_currentPage]),
          // Floating vertical navbar on top of content
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: NavigationView(
              floating: true,
              vertical: true,
              floatingMarginLeft: 12,
              visible: _navVisible,
              toastController: _navToast,
              onChangePage: (i) => setState(() => _currentPage = i),
              selectedIndex: _currentPage,
              curve: Curves.fastLinearToSlowEaseIn,
              durationAnimation: const Duration(milliseconds: 500),
              backgroundColor: theme.scaffoldBackgroundColor,
              color: primaryColor,
              enableGlassmorphism: true,
              items: navItems,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard Page ──────────────────────────────────────────────────────────

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({this.scrollController});
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FrostedScaffold(
      title: 'Nebula Dashboard',
      actions: [
        IconButton(
          icon: Icon(
            theme.brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          onPressed: () => MannyShowcaseApp.of(context).toggleTheme(),
        ),
        IconButton(
          icon: const Icon(IconlyBroken.setting),
          onPressed: () {
            OptionsMenu.show(
              context: context,
              title: 'Settings',
              options: [
                MenuOption(
                  icon: IconlyBroken.profile,
                  label: 'Account',
                  subtitle: 'Manage your profile',
                  onTap: () {},
                ),
                MenuOption(
                  icon: IconlyBroken.shield_done,
                  label: 'Security',
                  subtitle: 'Cluster encryption',
                  onTap: () {},
                ),
                MenuOption(
                  icon: IconlyBroken.logout,
                  label: 'Sign Out',
                  isDestructive: true,
                  onTap: () {},
                ),
              ],
            );
          },
        ),
      ],
      body: ListView(
        controller: scrollController,
        children: [
          // Cluster status — frosted glass card
          FrostedGlass(
            padding: UIConstants.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        IconlyBold.discovery,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cluster Alpha',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '12 nodes online',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    FrostedGlass(
                      borderRadius: BorderRadius.circular(20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shadow: false,
                      tintColor: Colors.green,
                      opacity: 0.15,
                      child: const Text(
                        'Healthy',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'CPU Usage',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                const ProgressBar(progress: 0.42, height: 10),
                const SizedBox(height: 4),
                Text(
                  '42% across all nodes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Memory',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                ProgressBar(
                  progress: 0.68,
                  height: 10,
                  progressColor: theme.colorScheme.tertiary,
                ),
                const SizedBox(height: 4),
                Text(
                  '68% — 5.4 GB / 8 GB',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Task deployment tracker — frosted
          FrostedGlass(
            padding: UIConstants.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Deployment',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                StepTracker(
                  steps: [
                    TrackerStep(
                      label: 'Created',
                      description: 'Task queued by master node',
                      icon: IconlyBroken.paper,
                      status: StepStatus.completed,
                      timestamp: '10:42 AM',
                    ),
                    TrackerStep(
                      label: 'Distributed',
                      description: 'Sent to 4 worker nodes via MQTT',
                      icon: IconlyBroken.send,
                      status: StepStatus.completed,
                      timestamp: '10:42 AM',
                    ),
                    TrackerStep(
                      label: 'Executing',
                      description: 'Workers processing task payload',
                      icon: IconlyBroken.activity,
                      status: StepStatus.active,
                      timestamp: '10:43 AM',
                    ),
                    TrackerStep(
                      label: 'Completed',
                      description: 'Results aggregated and reported',
                      icon: IconlyBroken.shield_done,
                      status: StepStatus.pending,
                    ),
                  ],
                  activeStepInfo: FrostedGlass(
                    borderRadius: BorderRadius.circular(8),
                    padding: const EdgeInsets.all(10),
                    shadow: false,
                    tintColor: Colors.blue,
                    opacity: 0.1,
                    child: Row(
                      children: [
                        const Icon(
                          IconlyBroken.time_circle,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Est. ~45s remaining',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Compact step tracker — frosted
          FrostedGlass(
            padding: UIConstants.paddingLG,
            child: StepTracker(
              isCompact: true,
              compactLabel: 'Plugin Install',
              steps: const [
                TrackerStep(
                  label: 'Download',
                  description: 'Fetching plugin binary',
                  icon: IconlyBroken.download,
                  status: StepStatus.completed,
                ),
                TrackerStep(
                  label: 'Verify',
                  description: 'Checking HMAC signature',
                  icon: IconlyBroken.shield_done,
                  status: StepStatus.completed,
                ),
                TrackerStep(
                  label: 'Load',
                  description: 'Loading into plugin runtime',
                  icon: IconlyBroken.upload,
                  status: StepStatus.active,
                ),
                TrackerStep(
                  label: 'Init',
                  description: 'Running plugin_init()',
                  icon: IconlyBroken.play,
                  status: StepStatus.pending,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick actions — frosted
          FrostedGlass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Quick Actions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ActionTile(
                  icon: IconlyBroken.scan,
                  title: 'Scan for Nodes',
                  onTap: () => NotificationToast.info(
                    context,
                    'Scanning local network via mDNS...',
                  ),
                ),
                ActionTile(
                  icon: IconlyBroken.upload,
                  title: 'Deploy Plugin',
                  onTap: () => NotificationToast.success(
                    context,
                    'Plugin deployed to 12 nodes!',
                  ),
                ),
                ActionTile(
                  icon: IconlyBroken.chart,
                  title: 'View Metrics',
                  onTap: () {},
                ),
                ActionTile(
                  icon: IconlyBroken.delete,
                  title: 'Reset Cluster',
                  isDestructive: true,
                  onTap: () => NotificationToast.error(
                    context,
                    'Cluster reset requires confirmation.',
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─── Components Page ─────────────────────────────────────────────────────────

class _ComponentsPage extends StatefulWidget {
  const _ComponentsPage({this.scrollController});
  final ScrollController? scrollController;

  @override
  State<_ComponentsPage> createState() => _ComponentsPageState();
}

class _ComponentsPageState extends State<_ComponentsPage> {
  double _rating = 3.0;
  String _selectedSort = 'recent';
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FrostedScaffold(
      title: 'Components',
      actions: [
        IconButton(
          icon: Icon(
            theme.brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          onPressed: () => MannyShowcaseApp.of(context).toggleTheme(),
        ),
      ],
      body: ListView(
        controller: widget.scrollController,
        children: [
          // Frosted text field
          _SectionTitle('Frosted Text Field'),
          FrostedGlass(
            padding: const EdgeInsets.all(4),
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Search nodes...',
                prefixIcon: const Icon(IconlyBroken.search),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Frosted buttons
          _SectionTitle('Frosted Buttons'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _FrostedButton(
                icon: IconlyBroken.upload,
                label: 'Deploy',
                color: theme.colorScheme.primary,
                onTap: () {},
              ),
              _FrostedButton(
                icon: IconlyBroken.shield_done,
                label: 'Verify',
                color: theme.colorScheme.tertiary,
                onTap: () {},
              ),
              _FrostedButton(
                icon: IconlyBroken.delete,
                label: 'Remove',
                color: theme.colorScheme.error,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Progress bars — frosted card
          _SectionTitle('Progress Bars'),
          FrostedGlass(
            padding: UIConstants.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Default'),
                const SizedBox(height: 8),
                const ProgressBar(progress: 0.75),
                const SizedBox(height: 16),
                const Text('Custom Color'),
                const SizedBox(height: 8),
                ProgressBar(
                  progress: 0.45,
                  progressColor: theme.colorScheme.tertiary,
                ),
                const SizedBox(height: 16),
                const Text('Small'),
                const SizedBox(height: 8),
                const ProgressBar(progress: 0.9, height: 6),
                const SizedBox(height: 16),
                const Text('Error state'),
                const SizedBox(height: 8),
                ProgressBar(
                  progress: 0.3,
                  progressColor: theme.colorScheme.error,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Rating — frosted
          _SectionTitle('Rating'),
          FrostedGlass(
            padding: UIConstants.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RatingDisplay(rating: 4.5, reviewCount: 128),
                const SizedBox(height: 12),
                const RatingDisplay(rating: 3.0, reviewCount: 42),
                const Divider(height: 24),
                RatingInput(
                  label: 'Rate this node',
                  initialRating: _rating,
                  onRatingChanged: (r) => setState(() => _rating = r),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Dropdown — frosted trigger
          _SectionTitle('Dropdown'),
          FrostedGlass(
            padding: UIConstants.paddingLG,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected: $_selectedSort',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                _FrostedButton(
                  icon: IconlyBroken.filter_2,
                  label: 'Sort By',
                  color: theme.colorScheme.primary,
                  onTap: () async {
                    final result = await CustomDropdown.show<String>(
                      context: context,
                      title: 'Sort Nodes By',
                      subtitle: 'Choose how to order the node list',
                      items: [
                        DropdownItem(
                          value: 'recent',
                          label: 'Most Recent',
                          subtitle: 'Last seen time',
                          icon: IconlyBroken.time_circle,
                        ),
                        DropdownItem(
                          value: 'battery',
                          label: 'Battery Level',
                          subtitle: 'Highest charge first',
                          icon: IconlyBroken.chart,
                        ),
                        DropdownItem(
                          value: 'load',
                          label: 'CPU Load',
                          subtitle: 'Lowest utilization first',
                          icon: IconlyBroken.activity,
                        ),
                        DropdownItem(
                          value: 'name',
                          label: 'Name',
                          subtitle: 'Alphabetical order',
                          icon: IconlyBroken.filter,
                        ),
                      ],
                      currentValue: _selectedSort,
                    );
                    if (result != null) {
                      setState(() => _selectedSort = result);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notification cards
          _SectionTitle('Notification Cards'),
          _NotificationCard(
            icon: IconlyBroken.shield_done,
            color: Colors.green,
            title: 'Node Joined',
            subtitle: 'node-bravo-02 connected to cluster',
            time: '2m ago',
          ),
          const SizedBox(height: 10),
          _NotificationCard(
            icon: IconlyBroken.danger,
            color: Colors.red,
            title: 'Connection Lost',
            subtitle: 'node-delta-03 went offline unexpectedly',
            time: '5m ago',
          ),
          const SizedBox(height: 10),
          _NotificationCard(
            icon: IconlyBroken.info_circle,
            color: Colors.blue,
            title: 'Update Available',
            subtitle: 'Nebula Engine v0.5.0 ready to deploy',
            time: '12m ago',
          ),
          const SizedBox(height: 10),
          _NotificationCard(
            icon: IconlyBroken.chart,
            color: Colors.orange,
            title: 'High CPU',
            subtitle: 'node-alpha-01 at 92% utilization',
            time: '18m ago',
          ),

          const SizedBox(height: 24),

          // AI Voice Visualizer
          _SectionTitle('AI Voice Visualizer'),
          _AudioVisualizerCard(
            title: 'Siri iOS 9',
            subtitle: 'Authentic multi-layer additive blend',
            style: VoiceVisualizerStyle.siriIos9,
            height: 130,
          ),
          const SizedBox(height: 12),
          _AudioVisualizerCard(
            title: 'Siri Wave',
            style: VoiceVisualizerStyle.siriWave,
            height: 110,
          ),
          const SizedBox(height: 12),
          _AudioVisualizerCard(
            title: 'Gemini Band',
            style: VoiceVisualizerStyle.geminiBand,
            height: 110,
          ),
          const SizedBox(height: 12),
          _AudioVisualizerCard(
            title: 'Fluid Blob',
            style: VoiceVisualizerStyle.fluidBlob,
            height: 190,
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─── Modals Page ─────────────────────────────────────────────────────────────

class _ModalsPage extends StatefulWidget {
  const _ModalsPage({this.scrollController});
  final ScrollController? scrollController;

  @override
  State<_ModalsPage> createState() => _ModalsPageState();
}

class _ModalsPageState extends State<_ModalsPage> {
  String? _selectedRegion;

  static const _mockNodes = [
    'node-alpha-01',
    'node-alpha-02',
    'node-bravo-01',
    'node-bravo-02',
    'node-charlie-01',
    'node-delta-01',
    'node-delta-02',
    'node-delta-03',
    'node-echo-01',
    'node-foxtrot-01',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FrostedScaffold(
      title: 'Modals & Sheets',
      actions: [
        IconButton(
          icon: Icon(
            theme.brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          onPressed: () => MannyShowcaseApp.of(context).toggleTheme(),
        ),
      ],
      body: ListView(
        controller: widget.scrollController,
        children: [
          // ── Cupertino Modals (the effect you like) ──
          _SectionTitle('Cupertino Modals'),
          Text(
            'iOS-style slide up with previous page scaling down',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FrostedButton(
                icon: IconlyBroken.arrow_up,
                label: 'Fullscreen Modal',
                color: theme.colorScheme.primary,
                onTap: () => showFrostedCupertinoSheet(
                  context: context,
                  expand: true,
                  builder: (context) => _CupertinoModalDemo(),
                ),
              ),
              _FrostedButton(
                icon: IconlyBroken.message,
                label: 'Comments Style',
                color: theme.colorScheme.secondary,
                onTap: () => showFrostedCupertinoSheet(
                  context: context,
                  builder: (context) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: _CommentsStyleDemo(),
                  ),
                ),
              ),
              _FrostedButton(
                icon: IconlyBroken.arrow_up_2,
                label: 'Bar Modal',
                color: theme.colorScheme.tertiary,
                onTap: () => showFrostedBarSheet(
                  context: context,
                  builder: (context) => SizedBox(
                    height: 300,
                    child: Padding(
                      padding: UIConstants.paddingLG,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            'Bar Modal',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bar-style frosted modal. '
                            'Notice the top handle bar.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          const ProgressBar(progress: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Alert Dialogs ──
          _SectionTitle('Alert Dialogs'),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FrostedButton(
                icon: IconlyBroken.swap,
                label: 'Confirm',
                color: theme.colorScheme.primary,
                onTap: () => AppAlertDialog.show(
                  context: context,
                  title: 'Rotate Master?',
                  message:
                      'This will trigger V-formation scoring and promote '
                      'the highest-ranked node.',
                  actionText: 'Rotate',
                  onActionPressed: () => NotificationToast.success(
                    context,
                    'Master rotation initiated.',
                  ),
                ),
              ),
              _FrostedButton(
                icon: IconlyBroken.delete,
                label: 'Danger',
                color: Colors.red,
                onTap: () => AppAlertDialog.showDanger(
                  context: context,
                  title: 'Delete Cluster?',
                  message:
                      'This will permanently remove all 12 nodes. '
                      'This action cannot be undone.',
                  actionText: 'Delete Forever',
                  onActionPressed: () =>
                      NotificationToast.error(context, 'Cluster deleted.'),
                ),
              ),
              _FrostedButton(
                icon: IconlyBroken.edit,
                label: 'With Input',
                color: theme.colorScheme.primary,
                onTap: () => AppAlertDialog.showWithInput(
                  context: context,
                  title: 'Rename Node',
                  message: 'Enter a new display name for node-alpha-01.',
                  hintText: 'e.g. living-room-pixel',
                  initialValue: 'node-alpha-01',
                  actionText: 'Rename',
                  validator: (v) => v.isEmpty ? 'Name cannot be empty' : null,
                  onActionPressed: (name) =>
                      NotificationToast.success(context, 'Renamed to "$name".'),
                ),
              ),
              _FrostedButton(
                icon: IconlyBroken.info_circle,
                label: 'Info',
                color: theme.colorScheme.tertiary,
                onTap: () => AppAlertDialog.showInfo(
                  context: context,
                  title: 'Cluster Info',
                  message:
                      'Cluster Alpha running v0.4.2 — 12 active nodes '
                      'across 3 regions. Uptime: 14d 6h.',
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Search ──
          _SectionTitle('Search Sheet'),
          _FrostedButton(
            icon: IconlyBroken.search,
            label: 'Open Search',
            color: theme.colorScheme.primary,
            onTap: () => SearchSheet.show<String>(
              context: context,
              hintText: 'Search nodes...',
              searchHistory: const ['node-alpha', 'node-delta', 'bravo'],
              onClearHistory: () {},
              onDeleteHistoryItem: (_) {},
              onSearch: (query) async {
                await Future.delayed(const Duration(milliseconds: 400));
                return _mockNodes
                    .where((n) => n.toLowerCase().contains(query.toLowerCase()))
                    .toList();
              },
              itemBuilder: (context, node) => ListTile(
                leading: FrostedGlass(
                  borderRadius: BorderRadius.circular(10),
                  shadow: false,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      IconlyBroken.discovery,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
                title: Text(node),
                subtitle: Text(
                  node.contains('alpha')
                      ? 'Online — Master'
                      : 'Online — Worker',
                ),
              ),
              onItemSelected: (node) {
                Navigator.pop(context);
                NotificationToast.info(context, 'Selected: $node');
              },
            ),
          ),

          const SizedBox(height: 32),

          // ── Filter ──
          _SectionTitle('Filter Sheet'),
          _FrostedButton(
            icon: IconlyBroken.filter,
            label: 'Open Filters',
            color: theme.colorScheme.primary,
            onTap: () => FilterSheet.show(
              context: context,
              title: 'Filter Nodes',
              groups: [
                FilterGroup(
                  id: 'status',
                  label: 'Status',
                  icon: IconlyBroken.shield_done,
                  type: FilterGroupType.chips,
                  options: const [
                    FilterOption(id: 'online', label: 'Online'),
                    FilterOption(id: 'offline', label: 'Offline'),
                    FilterOption(id: 'idle', label: 'Idle'),
                    FilterOption(id: 'busy', label: 'Busy'),
                  ],
                  initialValue: 'online',
                ),
                FilterGroup(
                  id: 'role',
                  label: 'Role',
                  icon: IconlyBroken.user_3,
                  type: FilterGroupType.pills,
                  options: const [
                    FilterOption(id: 'master', label: 'Master'),
                    FilterOption(id: 'worker', label: 'Worker'),
                    FilterOption(id: 'standby', label: 'Standby'),
                  ],
                ),
                FilterGroup(
                  id: 'battery',
                  label: 'Battery Level',
                  icon: IconlyBroken.chart,
                  type: FilterGroupType.rangeSlider,
                  rangeConfig: RangeFilterConfig(
                    min: 0,
                    max: 100,
                    divisions: 20,
                    labelFormatter: (v) => '${v.round()}%',
                  ),
                ),
              ],
              onApply: (results) => NotificationToast.success(
                context,
                'Filters applied: ${results.entries.where((e) => e.value != null).length} active',
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Selection ──
          _SectionTitle('Selection Sheet'),
          SelectionField<String>(
            label: 'Deployment Region',
            hint: 'Select a region',
            icon: IconlyBroken.location,
            value: _selectedRegion,
            displayText: _selectedRegion,
            sheetTitle: 'Select Region',
            searchHint: 'Search regions...',
            favorites: const ['us-east-1', 'eu-west-1'],
            items: const [
              SelectionItem(
                value: 'us-east-1',
                label: 'US East (Virginia)',
                icon: IconlyBroken.location,
              ),
              SelectionItem(
                value: 'us-west-2',
                label: 'US West (Oregon)',
                icon: IconlyBroken.location,
              ),
              SelectionItem(
                value: 'eu-west-1',
                label: 'EU West (Ireland)',
                icon: IconlyBroken.location,
              ),
              SelectionItem(
                value: 'eu-central-1',
                label: 'EU Central (Frankfurt)',
                icon: IconlyBroken.location,
              ),
              SelectionItem(
                value: 'ap-southeast-1',
                label: 'Asia (Singapore)',
                icon: IconlyBroken.location,
              ),
            ],
            onSelected: (v) => setState(() => _selectedRegion = v),
          ),

          const SizedBox(height: 32),

          // ── Share ──
          _SectionTitle('Share Menu'),
          _FrostedButton(
            icon: IconlyBroken.send,
            label: 'Share Invite',
            color: theme.colorScheme.primary,
            onTap: () => ShareMenu.show(
              context: context,
              title: 'Share Cluster Invite',
              platforms: ShareMenu.defaultPlatforms(
                onWhatsApp: () =>
                    NotificationToast.success(context, 'Shared via WhatsApp'),
                onTelegram: () =>
                    NotificationToast.success(context, 'Shared via Telegram'),
                onEmail: () =>
                    NotificationToast.success(context, 'Shared via Email'),
                onCopyLink: () =>
                    NotificationToast.info(context, 'Link copied'),
                onMore: () {},
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─── Feedback Page ───────────────────────────────────────────────────────────

class _FeedbackPage extends StatelessWidget {
  const _FeedbackPage({this.scrollController});
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FrostedScaffold(
      title: 'Notifications',
      actions: [
        IconButton(
          icon: Icon(
            theme.brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
          onPressed: () => MannyShowcaseApp.of(context).toggleTheme(),
        ),
      ],
      body: ListView(
        controller: scrollController,
        children: [
          _SectionTitle('Toast Notifications'),
          Text(
            'Tap each to see the frosted toast',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FrostedButton(
                icon: IconlyBroken.shield_done,
                label: 'Success',
                color: Colors.green,
                onTap: () => NotificationToast.success(
                  context,
                  'Node successfully joined the cluster!',
                ),
              ),
              _FrostedButton(
                icon: IconlyBroken.danger,
                label: 'Error',
                color: Colors.red,
                onTap: () => NotificationToast.error(
                  context,
                  'Connection to worker node-07 lost.',
                ),
              ),
              _FrostedButton(
                icon: IconlyBroken.info_square,
                label: 'Warning',
                color: Colors.orange,
                onTap: () => NotificationToast.warning(
                  context,
                  'Battery below 20% on 3 nodes.',
                ),
              ),
              _FrostedButton(
                icon: IconlyBroken.info_circle,
                label: 'Info',
                color: theme.colorScheme.primary,
                onTap: () => NotificationToast.info(
                  context,
                  'Firmware update available for cluster.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _FrostedButton(
            icon: IconlyBroken.arrow_down,
            label: 'Bottom Toast with Action',
            color: theme.colorScheme.primary,
            onTap: () => NotificationToast.show(
              context: context,
              message: 'Plugin deployed to all nodes.',
              type: NotificationType.success,
              actionLabel: 'UNDO',
              onActionPressed: () {},
              position: ToastPosition.bottomCenter,
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle('Navbar Toast'),
          Text(
            'Toast shown through the floating navbar',
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FrostedButton(
                icon: IconlyBroken.shield_done,
                label: 'Nav Success',
                color: Colors.green,
                onTap: () => NotificationToast.show(
                  context: context,
                  message: 'Node joined cluster!',
                  type: NotificationType.success,
                  useNav: true,
                ),
              ),
              _FrostedButton(
                icon: IconlyBroken.danger,
                label: 'Nav Error',
                color: Colors.red,
                onTap: () => NotificationToast.show(
                  context: context,
                  message: 'Connection lost to node-07',
                  type: NotificationType.error,
                  useNav: true,
                ),
              ),
              _FrostedButton(
                icon: IconlyBroken.info_circle,
                label: 'Nav Info',
                color: theme.colorScheme.primary,
                onTap: () => NotificationToast.show(
                  context: context,
                  message: 'Firmware update available',
                  type: NotificationType.info,
                  useNav: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Theme palette — frosted
          _SectionTitle('Theme Palette'),
          FrostedGlass(
            padding: UIConstants.paddingLG,
            child: Column(
              children: [
                _ColorRow('Primary', theme.colorScheme.primary),
                _ColorRow('Secondary', theme.colorScheme.secondary),
                _ColorRow('Tertiary', theme.colorScheme.tertiary),
                _ColorRow('Error', theme.colorScheme.error),
                _ColorRow('Surface', theme.colorScheme.surface),
                _ColorRow(
                  'Primary Container',
                  theme.colorScheme.primaryContainer,
                ),
                _ColorRow(
                  'Secondary Container',
                  theme.colorScheme.secondaryContainer,
                ),
              ],
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─── Cupertino Modal Demos ───────────────────────────────────────────────────

class _CupertinoModalDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FrostedScaffold(
      title: 'Fullscreen Modal',
      // Transparent so the FrostedSheetSurface from the modal route shows
      // through. Without this, Scaffold's default backgroundColor paints
      // an opaque layer over the frost.
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(context),
      ),
      body: ListView(
        children: [
            FrostedGlass(
              padding: UIConstants.paddingLG,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cupertino Modal',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is the iOS-style modal where the previous page '
                    'scales down behind it. Uses showCupertinoModalBottomSheet '
                    'with expand: true.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FrostedGlass(
              padding: UIConstants.paddingLG,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProgressBar(progress: 0.72),
                  const SizedBox(height: 16),
                  StepTracker(
                    isCompact: true,
                    compactLabel: 'Task Progress',
                    steps: const [
                      TrackerStep(
                        label: 'Queue',
                        description: 'Queued',
                        icon: IconlyBroken.time_circle,
                        status: StepStatus.completed,
                      ),
                      TrackerStep(
                        label: 'Run',
                        description: 'Running',
                        icon: IconlyBroken.play,
                        status: StepStatus.active,
                      ),
                      TrackerStep(
                        label: 'Done',
                        description: 'Complete',
                        icon: IconlyBroken.shield_done,
                        status: StepStatus.pending,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FrostedGlass(
              padding: UIConstants.paddingLG,
              child: const RatingDisplay(rating: 4.5, reviewCount: 128),
            ),
          ],
        ),
    );
  }
}

class _CommentsStyleDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FrostedGlass.sheet(
      topRadius: 20,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Comments',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 8,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FrostedGlass(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.2,
                          ),
                          child: Text(
                            'N${i + 1}',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'node-worker-0${i + 1}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                i.isEven
                                    ? 'Task completed successfully in 42s.'
                                    : 'Plugin loaded. Running health check...',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${i + 1}m',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable Helpers ────────────────────────────────────────────────────────

class _FrostedButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FrostedButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: FrostedGlass(
        borderRadius: BorderRadius.circular(14),
        tintColor: color,
        opacity: 0.15,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _NotificationCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FrostedGlass(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          FrostedGlass(
            borderRadius: BorderRadius.circular(12),
            shadow: false,
            tintColor: color,
            opacity: 0.15,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: color, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioVisualizerCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final VoiceVisualizerStyle style;
  final double height;

  const _AudioVisualizerCard({
    required this.title,
    required this.style,
    required this.height,
    this.subtitle,
  });

  @override
  State<_AudioVisualizerCard> createState() => _AudioVisualizerCardState();
}

class _AudioVisualizerCardState extends State<_AudioVisualizerCard> {
  final _player = AudioPlayer();
  bool _playing = false;
  var _bands = [0.0, 0.0, 0.0, 0.0];
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Timer? _tickTimer;
  AudioSpectrum? _spectrum;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        _tickTimer?.cancel();
        setState(() { _playing = false; _bands = [0, 0, 0, 0]; });
      }
    });
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      try { await _player.pause(); } catch (_) {}
      _tickTimer?.cancel();
      setState(() { _playing = false; _bands = [0, 0, 0, 0]; });
      return;
    }

    // Step 1: Decode to PCM if not done yet (fast — ~0.5s, no FFT)
    if (_spectrum == null) {
      try {
        final bytes = await rootBundle.load('assets/the_architect.mp3');
        _spectrum = await AudioSpectrum.decode(
          bytes.buffer.asUint8List(),
          'mp3',
        );
        debugPrint('Decoded: ${_spectrum!.durationMs.round()}ms');
      } catch (e) {
        debugPrint('Decode error: $e');
      }
    }

    // Step 2: Start playback
    try {
      if (_player.state != PlayerState.paused) {
        await _player.setSource(AssetSource('the_architect.mp3'));
      }
      await _player.resume();
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
    setState(() => _playing = true);

    // Step 3: 60fps tick — each frame runs ONE FFT at current position (<1ms)
    _tickTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_playing || !mounted) return;
      if (_spectrum != null && _spectrum!.hasData) {
        setState(() {
          _bands = _spectrum!.getBandsAt(_position.inMilliseconds);
        });
      }
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return FrostedGlass(
      padding: UIConstants.paddingLG,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(widget.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5))),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: _togglePlay,
                child: FrostedGlass(
                  borderRadius: BorderRadius.circular(20),
                  shadow: false,
                  tintColor: theme.colorScheme.primary,
                  opacity: 0.15,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      _playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _playing
              ? VoiceVisualizer(
                  bands: List.from(_bands),
                  style: widget.style,
                  height: widget.height,
                )
              : VoiceVisualizer.demo(
                  style: widget.style,
                  speaking: false,
                  height: widget.height,
                ),
          if (_duration.inMilliseconds > 0) ...[
            const SizedBox(height: 10),
            ProgressBar(progress: progress, height: 4),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(_position),
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5))),
                Text('The Architect',
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6))),
                Text(_fmt(_duration),
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String label;
  final Color color;
  const _ColorRow(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
