import 'package:app_mensagem/pages/recursos/button.dart';
import 'package:app_mensagem/pages/recursos/logo.dart';
import 'package:app_mensagem/pages/recursos/text_field.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RegisterEnterprise extends StatefulWidget {
  const RegisterEnterprise({super.key});

  @override
  State<RegisterEnterprise> createState() => _RegisterEnterpriseState();
}

class _RegisterEnterpriseState extends State<RegisterEnterprise> {
  final TextEditingController _codigoController = TextEditingController();
  late final TextEditingController _cnpjController = TextEditingController()
    ..addListener(onCnpjChanged);

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
                const SizedBox(height: 15),
                //Mensagem para criação de contas
                const Text(
                  "Registre sua Empresa",
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: BorderSide.strokeAlignInside),
                ),
                //Espaçamento
                const SizedBox(height: 25),
                //Entrada de Valor
                MyTextField(
                    controller: _codigoController,
                    labelText: 'Código da Empresa',
                    obscureText: false),
                //Espaçamento
                const SizedBox(height: 25),
                //Entrada de Valor
                MyTextField(
                  controller: _cnpjController,
                  labelText: 'CNPJ da Empresa',
                  obscureText: false,
                  isCnpjField: true,
                ),
                //Espaçamento
                const SizedBox(height: 25),

                MyButton(
                  onTap: () async {
                    CollectionReference enterprises =
                        FirebaseFirestore.instance.collection('enterprise');
                    QuerySnapshot snapshot = await enterprises.get();

                    bool isCnpjRegistered = false;

                    for (var doc in snapshot.docs) {
                      var data = doc.data() as Map<String, dynamic>?;
                      String? cnpj = data?['cnpj'];

                      if (_cnpjController.text == cnpj) {
                        isCnpjRegistered = true;

                        setState(() {
                          const snackBar = SnackBar(
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.transparent,
                            content: AwesomeSnackbarContent(
                                title: 'Cnpj já cadastrado',
                                message: 'Favor cadastrar outro Cnpj',
                                contentType: ContentType.failure),
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(snackBar);
                        });
                        break; // Interrompe o loop ao encontrar o CNPJ
                      }
                    }

                    if (!isCnpjRegistered) {
                      await createEnterprise(
                          _codigoController.text, _cnpjController.text);
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Empresa cadastrada com sucesso'),
                        ),
                      );
                    }
                  },
                  text: 'Cadastrar Empresa',
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  /////////////////////
  /// Método para cuidar do estado da mudança e digitação do CNPJ. Sempre que termina de digitar o CPNJ, ele é validado.
  void onCnpjChanged() {
    if (_cnpjController.text.length == 14) {
      if (validarCNPJ(_cnpjController.text)) {
        setState(() {
          const snackBar = SnackBar(
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            content: AwesomeSnackbarContent(
                title: 'Cnpj válido',
                message: '',
                contentType: ContentType.success),
          );
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(snackBar);
        });
      } else {
        const snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
              title: 'Cnpj Inválido',
              message: 'Favor escrever um CNPJ válido',
              contentType: ContentType.failure),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    }
  }

  ///////////////////////////
  ///Método para validar o cnpj fornecido
  bool validarCNPJ(String cnpj) {
    // Remove caracteres especiais
    cnpj = cnpj.replaceAll(RegExp(r'\D'), '');

    // Verifica se o CNPJ tem 14 dígitos
    if (cnpj.length != 14) return false;

    // Verifica se todos os dígitos são iguais, o que torna o CNPJ inválido
    if (RegExp(r'^(\d)\1*$').hasMatch(cnpj)) return false;

    // Arrays de multiplicadores para os dígitos verificadores
    List<int> multiplicador1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    List<int> multiplicador2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    // Função para calcular cada dígito verificador
    int calcularDigito(String str, List<int> multiplicador) {
      int soma = 0;
      for (int i = 0; i < multiplicador.length; i++) {
        soma += int.parse(str[i]) * multiplicador[i];
      }
      int resto = soma % 11;
      return (resto < 2) ? 0 : 11 - resto;
    }

    // Calcular os dois últimos dígitos
    int digito1 = calcularDigito(cnpj.substring(0, 12), multiplicador1);
    int digito2 = calcularDigito(
        cnpj.substring(0, 12) + digito1.toString(), multiplicador2);

    // Verifica se os dígitos calculados são iguais aos fornecidos
    return cnpj.endsWith('$digito1$digito2');
  }

  ////////////////////
  /// Método para criar a empresa no banco de dados
  Future<void> createEnterprise(String codigo, String cnpj) async {
    try {
      await FirebaseFirestore.instance
          .collection('enterprise')
          .doc(codigo.toLowerCase())
          .set(
        {
          'code': codigo.toLowerCase(),
          'cnpj': cnpj,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Erro ao cadastrar a empresa: $e');
    }
  }
}
