import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_model.dart';
import '../../models/lan_game_model.dart';
import '../../services/lan_game_service.dart';
import '../../theme/app_theme.dart';
import '../game/game_screen.dart';

/// Tela de lobby LAN - Similar ao Mario Party
/// Permite hospedar ou entrar em jogos na rede local
class LanLobbyScreen extends StatefulWidget {
  const LanLobbyScreen({super.key});

  @override
  State<LanLobbyScreen> createState() => _LanLobbyScreenState();
}

class _LanLobbyScreenState extends State<LanLobbyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _nameController = TextEditingController(text: 'Jogador');
  GameVariant _selectedVariant = GameVariant.american;
  bool _isHosting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Escuta por conexões
    final lanService = context.read<LanGameService>();
    lanService.addListener(_checkConnection);
  }

  void _checkConnection() {
    final lanService = context.read<LanGameService>();

    if (lanService.status == LanConnectionStatus.connected) {
      // Conectado! Navegar para tela de jogo
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      }
    }
  }

  Future<void> _hostGame() async {
    final lanService = context.read<LanGameService>();

    lanService.setPlayerName(_nameController.text.trim().isEmpty
        ? 'Jogador'
        : _nameController.text.trim());
    lanService.setVariant(_selectedVariant);

    setState(() => _isHosting = true);

    final success = await lanService.hostGame();

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao hospedar jogo. Verifique sua conexão Wi-Fi.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isHosting = false);
    }
  }

  Future<void> _discoverGames() async {
    final lanService = context.read<LanGameService>();
    await lanService.discoverGames();
  }

  Future<void> _joinGame(LanGameAdvertisement game) async {
    final lanService = context.read<LanGameService>();

    lanService.setPlayerName(_nameController.text.trim().isEmpty
        ? 'Jogador'
        : _nameController.text.trim());

    final success = await lanService.joinGame(game);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao conectar ao jogo.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelHosting() async {
    final lanService = context.read<LanGameService>();
    await lanService.cleanup();
    setState(() => _isHosting = false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    final lanService = context.read<LanGameService>();
    lanService.removeListener(_checkConnection);
    lanService.cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lanService = context.watch<LanGameService>();

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await lanService.cleanup();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jogo Local (LAN)'),
          backgroundColor: AppColors.background,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Informação sobre modo não ranqueado
                Card(
                  color: AppColors.accent.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Jogo casual - não afeta seu ranking',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo de nome
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Seu Nome',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.textSecondary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.accent),
                    ),
                  ),
                  maxLength: 20,
                ),
                const SizedBox(height: 16),

                // Seleção de variante
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textSecondary),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<GameVariant>(
                    value: _selectedVariant,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: GameVariant.american,
                        child: Text('Damas Americanas'),
                      ),
                      DropdownMenuItem(
                        value: GameVariant.brazilian,
                        child: Text('Damas Brasileiras'),
                      ),
                    ],
                    onChanged: (variant) {
                      if (variant != null) {
                        setState(() => _selectedVariant = variant);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Botão de hospedar
                if (!_isHosting && lanService.status == LanConnectionStatus.disconnected)
                  ElevatedButton.icon(
                    onPressed: _hostGame,
                    icon: const Icon(Icons.wifi_tethering),
                    label: const Text('Hospedar Jogo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),

                // Status de hospedagem
                if (_isHosting || lanService.status == LanConnectionStatus.hosting)
                  Card(
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          RotationTransition(
                            turns: _animationController,
                            child: Icon(
                              Icons.wifi_tethering,
                              size: 48,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aguardando jogador...',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Outros jogadores podem ver seu jogo na rede',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _cancelHosting,
                            child: const Text('Cancelar'),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Divider
                if (!_isHosting && lanService.status == LanConnectionStatus.disconnected)
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.textSecondary)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OU',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.textSecondary)),
                    ],
                  ),

                const SizedBox(height: 16),

                // Botão de procurar jogos
                if (!_isHosting && lanService.status == LanConnectionStatus.disconnected)
                  ElevatedButton.icon(
                    onPressed: _discoverGames,
                    icon: const Icon(Icons.search),
                    label: const Text('Procurar Jogos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.accent,
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(color: AppColors.accent),
                    ),
                  ),

                const SizedBox(height: 16),

                // Lista de jogos disponíveis
                if (lanService.status == LanConnectionStatus.discovering)
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Jogos Disponíveis',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              color: AppColors.accent,
                              onPressed: _discoverGames,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: lanService.availableGames.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      RotationTransition(
                                        turns: _animationController,
                                        child: Icon(
                                          Icons.wifi_find,
                                          size: 48,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Procurando jogos na rede local...',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Certifique-se de estar na mesma rede Wi-Fi',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: lanService.availableGames.length,
                                  itemBuilder: (context, index) {
                                    final game = lanService.availableGames[index];
                                    return Card(
                                      color: AppColors.surface,
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.accent,
                                          child: Icon(
                                            Icons.person,
                                            color: AppColors.background,
                                          ),
                                        ),
                                        title: Text(
                                          game.hostName,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          game.variant == GameVariant.american
                                              ? 'Damas Americanas'
                                              : 'Damas Brasileiras',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        trailing: ElevatedButton(
                                          onPressed: () => _joinGame(game),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.accent,
                                            foregroundColor: AppColors.background,
                                          ),
                                          child: const Text('Entrar'),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
