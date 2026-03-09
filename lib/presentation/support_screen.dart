import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../infrastructure/purchase_service.dart';

/// Pantalla de apoyo al desarrollador con tip jar
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool _isLoading = false;
  bool _hasSupported = false;
  List<TipProduct> _tips = [];
  final _purchaseService = PurchaseService();

  @override
  void initState() {
    super.initState();
    _checkSupporterStatus();
    _loadTips();
  }

  Future<void> _checkSupporterStatus() async {
    final isSupporter = await _purchaseService.isSupporter();
    if (!isSupporter) {
      final prefs = await SharedPreferences.getInstance();
      final localSupporter = prefs.getBool('is_supporter') ?? false;
      if (mounted) setState(() => _hasSupported = localSupporter);
    } else {
      if (mounted) setState(() => _hasSupported = true);
    }
  }

  Future<void> _loadTips() async {
    final tips = await _purchaseService.getAvailableTips();
    if (mounted) setState(() => _tips = tips);
  }

  Future<void> _handleTip(TipProduct tip) async {
    if (_isLoading) return;
    
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      final result = await _purchaseService.purchaseTip(tip);

      if (result.success && result.isSupporter) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_supporter', true);
        if (mounted) setState(() => _hasSupported = true);
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(result.success ? '💚 ¡Gracias!' : 'Aviso'),
            content: Text(result.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    try {
      final result = await _purchaseService.restorePurchases();

      if (result.isSupporter) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_supporter', true);
        if (mounted) setState(() => _hasSupported = true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const _tipEmojis = ['☕', '🌮', '🚀'];

  List<Widget> _buildTipOptions() {
    final tips = _tips;

    if (tips.isEmpty) {
      return [
        _TipOption(
          emoji: '☕',
          title: 'Un cafecito',
          subtitle: 'Para las noches de código',
          price: '\$0.99',
          onTap: () => _handleTip(TipProduct(id: 'coffee', title: 'Cafecito', description: 'Para las noches de código', priceString: '\$0.99')),
          isLoading: _isLoading,
        ),
        const SizedBox(height: 12),
        _TipOption(
          emoji: '🌮',
          title: 'Unos tacos',
          subtitle: 'Combustible mexicano',
          price: '\$2.99',
          onTap: () => _handleTip(TipProduct(id: 'tacos', title: 'Tacos', description: 'Combustible mexicano', priceString: '\$2.99')),
          isLoading: _isLoading,
          isPopular: true,
        ),
        const SizedBox(height: 12),
        _TipOption(
          emoji: '🚀',
          title: 'Mega apoyo',
          subtitle: 'Eres increíble',
          price: '\$9.99',
          onTap: () => _handleTip(TipProduct(id: 'mega', title: 'Mega apoyo', description: 'Eres increíble', priceString: '\$9.99')),
          isLoading: _isLoading,
        ),
      ];
    }

    return [
      for (int i = 0; i < tips.length; i++) ...[
        _TipOption(
          emoji: i < _tipEmojis.length ? _tipEmojis[i] : '💚',
          title: tips[i].title,
          subtitle: tips[i].description,
          price: tips[i].priceString,
          onTap: () => _handleTip(tips[i]),
          isLoading: _isLoading,
          isPopular: i == 1,
        ),
        if (i < tips.length - 1) const SizedBox(height: 12),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apoyar'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header con corazón
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('💚', style: TextStyle(fontSize: 48)),
              ),
            ).animate().scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut),
            
            const SizedBox(height: 24),
            
            // Título
            Text(
              'Apoya el desarrollo',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms),
            
            const SizedBox(height: 8),
            
            Text(
              'Esta app es 100% gratis, sin anuncios ni suscripciones',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),
            
            const SizedBox(height: 32),
            
            // Historia
            _StoryCard(isDark: isDark, colorScheme: colorScheme),
            
            const SizedBox(height: 32),
            
            // Tip jar
            Text(
              'Si te sirve y quieres apoyar:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tips loaded from RevenueCat (falls back to hardcoded)
            ..._buildTipOptions(),
            
            const SizedBox(height: 32),
            
            // Badge de supporter
            if (_hasSupported)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('💚', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Eres un Supporter!',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Gracias por tu apoyo',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
            
            const SizedBox(height: 24),
            
            // Restore purchases
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isLoading ? null : _restorePurchases,
              child: Text(
                'Restaurar compras',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Mensaje final
            Text(
              'Si no puedes apoyar económicamente, no pasa nada.\n'
              'Usa la app, mejora tus hábitos, y cuéntale a alguien.\n'
              'Eso también ayuda mucho. 💚',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

/// Card con la historia
class _StoryCard extends StatelessWidget {
  final bool isDark;
  final ColorScheme colorScheme;

  const _StoryCard({required this.isDark, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark 
            ? colorScheme.surface.withValues(alpha: 0.5)
            : colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🧠', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                '¿Por qué es gratis?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tengo TDAH. Necesitaba algo simple para mis hábitos diarios: '
            'tomar agua, medicamentos, las cosas que siempre olvido.\n\n'
            'Las apps que encontré eran complicadas o pedían suscripciones '
            'por funciones básicas.\n\n'
            'Así que hice esta app para mí, y decidí compartirla gratis '
            'para que otros como yo puedan usarla sin barreras.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}

/// Opción de tip
class _TipOption extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String price;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isPopular;

  const _TipOption({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.onTap,
    this.isLoading = false,
    this.isPopular = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPopular
                      ? colorScheme.primary
                      : isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                  width: isPopular ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            price,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isPopular)
          Positioned(
            top: -8,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Popular',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
