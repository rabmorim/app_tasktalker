import "package:app_mensagem/pages/recursos/button.dart";
import "package:app_mensagem/pages/recursos/logo.dart";
import "package:app_mensagem/pages/recursos/text_field.dart";
import "package:app_mensagem/pages/register_enterprise.dart";
import "package:app_mensagem/services/auth/auth_service.dart";
import "package:flutter/material.dart";

class Register extends StatefulWidget {
  final void Function()? onTap;
  const Register({super.key, this.onTap});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  //Obtendo o serviço de autenticação
  final authService = AuthService();

  //Text controllers e variaveis
  final _userName = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();

  //Lista de páginas
  late List<Widget> _pages;

  ///////////////////
  /// Método Cadastrar
  void cadastrar() async {
    //Verificando se as senhas são compativeis
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senhas não sao iguais, tente novamente!'),
        ),
      );
      return;
    }
    //Verificando se existe empresa com aquele código
    bool verifyEnterprise = await authService.verifyEnterprise(_codeController.text);
    if(verifyEnterprise == false){
         // ignore: use_build_context_synchronously
         ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Empresa nao existente'),
        ),
      );
      return;
    }

    //Verificando se o usuário ja existe
    bool verifyUser = await authService.verifyUser(_userName.text);
    // print(verifyUser.toString());
    if (verifyUser) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuário ja existente'),
        ),
      );
      return;
    }


    try {
      await authService.signUpWithEmailAndPassword(
          _emailController.text, _passwordController.text, _userName.text, _codeController.text);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      const Register(),
      const RegisterEnterprise(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _pages.length,
      child: Scaffold(
        appBar: AppBar(
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(-5),
            child: TabBar(
              tabAlignment: TabAlignment.fill,
              indicatorColor: Colors.white,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              indicatorSize: TabBarIndicatorSize
                  .label, // Deixa o indicador com o tamanho do label
              labelPadding: EdgeInsets.symmetric(horizontal: 16.0),
              tabs: [
                Tab(text: "Cadastrar"),
                Tab(text: "Cadastrar Empresa"),
              ],
              labelStyle: TextStyle(
                fontFamily: 'Nougat',
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //Espaçamento
                      const SizedBox(height: 5),
                      //Nome do app
                      const LogoWidget(titulo: 'TaskTalker'),
                      //Espaçamento
                      const SizedBox(height: 5),
                      //Mensagem para criação de contas
                      const Text(
                        "Registra-se",
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: BorderSide.strokeAlignInside),
                      ),
                      const SizedBox(height: 25),

                      //Nome de usuário
                      MyTextField(
                          controller: _userName,
                          labelText: 'Nome de Usuário',
                          obscureText: false),

                      const SizedBox(height: 20),
                      //Código de empresa
                      MyTextField(
                          controller: _codeController,
                          labelText: 'Código da empresa',
                          obscureText: false),
                      const SizedBox(height: 20),

                      //email textfield
                      MyTextField(
                          controller: _emailController,
                          labelText: 'Email',
                          obscureText: false),

                      //Espaçamento
                      const SizedBox(height: 20),

                      //senha textfield
                      MyTextField(
                          controller: _passwordController,
                          labelText: 'Senha',
                          obscureText: true),

                      //Espaçamento
                      const SizedBox(height: 20),

                      //Confirmação de senha texfiel
                      MyTextField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirme sua senha',
                          obscureText: true),

                      //Espaçamento
                      const SizedBox(height: 20),

                      // Registrar button
                      MyButton(
                          onTap: () {
                            cadastrar();
                          },
                          text: "Cadastrar"),

                      //Espaçamento entre botões

                      const SizedBox(height: 20),
                      // Registra-se

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: widget.onTap,
                            child: const Text(
                              "Já é membro? Realize o Login",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            //segunda aba com a lista de páginas
            _pages[1],
          ],
        ),
      ),
    );
  }
}
