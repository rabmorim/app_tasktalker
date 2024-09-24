import "package:app_mensagem/pages/recursos/button.dart";
import "package:app_mensagem/pages/recursos/logo.dart";
import "package:app_mensagem/pages/recursos/text_field.dart";
import "package:app_mensagem/services/auth/auth_service.dart";
import "package:flutter/material.dart";

class Register extends StatefulWidget {
  final void Function()? onTap;
   const Register({super.key, required this.onTap});


  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  //Obtendo o serviço de autenticação
  final authService = AuthService();

  //Text controllers e variaveis
  final userName = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  //Cadastrar
  void cadastrar() async {
    //Verificando se as senhas são compativeis
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senhas não sao iguais, tente novamente!'),
        ),
      );
      return;
      }

    //Verificando se o usuário ja existe
    bool verifyUser= await authService.verifyUser(userName.text);
    // print(verifyUser.toString());
    if(verifyUser){
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
          emailController.text, passwordController.text, userName.text);
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //Espaçamento
                const SizedBox(height: 15),
                //Nome do app
                const LogoWidget(titulo: 'TaskTalker'),
                //Espaçamento
                const SizedBox(height: 25),
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
                  controller: userName, 
                  labelText: 'Nome de Usuário', 
                  obscureText: false),
            
                   const SizedBox(height: 20),
            
                //email textfield
                MyTextField(
                    controller: emailController,
                    labelText: 'Email',
                    obscureText: false),
            
                //Espaçamento
                const SizedBox(height: 20),
            
                //senha textfield
                MyTextField(
                    controller: passwordController,
                    labelText: 'Senha',
                    obscureText: true),
            
                //Espaçamento
                const SizedBox(height: 20),
            
                //Confirmação de senha texfiel
                MyTextField(
                    controller: confirmPasswordController,
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
            
                const SizedBox(height: 20),
                // Registra-se
            
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        "Já é membro? Realize o Login",
                        style:
                            TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
