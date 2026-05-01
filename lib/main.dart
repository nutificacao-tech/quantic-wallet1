import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

void main() {
  runApp(QuanticWalletApp());
}

class QuanticWalletApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quantic Wallet',
      theme: ThemeData.dark().copyWith(
        primaryColor: Color(0xFF1a1a2e),
        scaffoldBackgroundColor: Color(0xFF1a1a2e),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF16213e),
          elevation: 0,
        ),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _verificarCarteira();
  }

  Future<void> _verificarCarteira() async {
    await Future.delayed(Duration(seconds: 1));
    final endereco = await storage.read(key: 'endereco');
    if (endereco == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WalletHome()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a2e),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text('Quantic Wallet', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('A moeda quântica do futuro', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 30),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _importController = TextEditingController();
  bool _isImporting = false;
  final storage = FlutterSecureStorage();

  String _gerarEndereco(List<int> publicKey) {
    final digest = sha256.convert(publicKey);
    return digest.toString().substring(0, 40);
  }

  Future<void> _criarCarteira() async {
    final random = Random.secure();
    final privateKey = List.generate(64, (_) => random.nextInt(256));
    final publicKey = List.generate(32, (_) => random.nextInt(256));
    final endereco = _gerarEndereco(publicKey);
    
    await storage.write(key: 'private_key', value: base64Encode(privateKey));
    await storage.write(key: 'public_key', value: base64Encode(publicKey));
    await storage.write(key: 'endereco', value: endereco);
    
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WalletHome()));
  }

  Future<void> _importarCarteira() async {
    setState(() => _isImporting = true);
    final privateKeyBase64 = _importController.text.trim();
    
    try {
      final privateKey = base64Decode(privateKeyBase64);
      final publicKey = List.generate(32, (_) => 0);
      final endereco = _gerarEndereco(publicKey);
      
      await storage.write(key: 'private_key', value: privateKeyBase64);
      await storage.write(key: 'public_key', value: base64Encode(publicKey));
      await storage.write(key: 'endereco', value: endereco);
      
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WalletHome()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chave inválida')));
    }
    setState(() => _isImporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a2e),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_balance_wallet, size: 80, color: Colors.white),
              SizedBox(height: 24),
              Text('Quantic Wallet', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Bem-vindo à era pós-quântica', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _criarCarteira,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('CRIAR NOVA CARTEIRA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => setState(() => _isImporting = !_isImporting),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('IMPORTAR CARTEIRA EXISTENTE'),
                ),
              ),
              if (_isImporting) ...[
                SizedBox(height: 16),
                TextField(
                  controller: _importController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Chave privada (base64)',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Color(0xFF2a2a3e),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isImporting ? null : _importarCarteira,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isImporting ? CircularProgressIndicator() : Text('IMPORTAR'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class WalletHome extends StatefulWidget {
  @override
  _WalletHomeState createState() => _WalletHomeState();
}

class _WalletHomeState extends State<WalletHome> {
  final storage = FlutterSecureStorage();
  
  String _endereco = "carregando...";
  double _saldo = 0.0;
  bool _carregando = true;
  String _mensagem = "";
  final String _apiUrl = "http://localhost:5000";

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _mensagem = "";
    });

    try {
      _endereco = await storage.read(key: 'endereco') ?? "não encontrado";
      
      final response = await http.get(
        Uri.parse("$_apiUrl/saldo/$_endereco"),
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _saldo = (data['saldo'] ?? 0).toDouble();
        _mensagem = "✅ Conectado à API";
      } else {
        _mensagem = "⚠️ API respondeu com erro ${response.statusCode}";
        _saldo = 0;
      }
    } catch (e) {
      _mensagem = "❌ API não está a correr em $_apiUrl";
      _saldo = 0;
    }

    setState(() {
      _carregando = false;
    });
  }

  Future<void> _sair() async {
    await storage.deleteAll();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quantic Wallet", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _carregarDados, tooltip: "Atualizar"),
          IconButton(icon: Icon(Icons.exit_to_app), onPressed: _sair, tooltip: "Sair"),
        ],
      ),
      body: _carregando
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text("Saldo Total", style: TextStyle(color: Colors.white70, fontSize: 16)),
                          SizedBox(height: 8),
                          Text("$_saldo QTC", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text("≈ \$${(_saldo * 0.05).toStringAsFixed(2)} USD", style: TextStyle(color: Colors.green, fontSize: 16)),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    if (_mensagem.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _mensagem.contains("✅") ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(_mensagem.contains("✅") ? Icons.check_circle : Icons.error, 
                                 color: _mensagem.contains("✅") ? Colors.green : Colors.red, size: 20),
                            SizedBox(width: 10),
                            Expanded(child: Text(_mensagem, style: TextStyle(fontSize: 12))),
                          ],
                        ),
                      ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Color(0xFF2a2a3e), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Seu endereço", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          SizedBox(height: 8),
                          SelectableText(_endereco, style: TextStyle(color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _acaoBotao(Icons.arrow_upward, "Enviar", Colors.blue, onTap: () => _mensagemTemporaria("Em desenvolvimento")),
                        _acaoBotao(Icons.arrow_downward, "Receber", Colors.green, onTap: () => _mostrarEndereco()),
                        _acaoBotao(Icons.history, "Histórico", Colors.orange, onTap: () => _mensagemTemporaria("Em desenvolvimento")),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _mensagemTemporaria(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _mostrarEndereco() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Receber QTC"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Envie QTC para este endereço:"),
            SizedBox(height: 10),
            SelectableText(_endereco, style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Fechar")),
        ],
      ),
    );
  }

  Widget _acaoBotao(IconData icon, String label, Color cor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 28)),
          SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}