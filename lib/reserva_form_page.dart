import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservaFormPage extends StatefulWidget {
  // Variáveis para receber os dados quando for modo de edição
  final String? reservaId;
  final Map<String, dynamic>? dadosAtuais;

  const ReservaFormPage({super.key, this.reservaId, this.dadosAtuais});

  @override
  State<ReservaFormPage> createState() => _ReservaFormPageState();
}

class _ReservaFormPageState extends State<ReservaFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _salaController = TextEditingController();
  final _dataController = TextEditingController();
  final _horarioController = TextEditingController();
  final _finalidadeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Se recebemos dados (modo edição), preenchemos os campos automaticamente
    if (widget.dadosAtuais != null) {
      _salaController.text = widget.dadosAtuais!['sala'] ?? '';
      _dataController.text = widget.dadosAtuais!['data'] ?? '';
      _horarioController.text = widget.dadosAtuais!['horario'] ?? '';
      _finalidadeController.text = widget.dadosAtuais!['finalidade'] ?? '';
    }
  }

  void _salvarReserva() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('Usuário não autenticado. Faça login novamente.');
        }

        final reservasRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('reservas');

        // Prepara o pacote de dados (não atualizamos o status nem a data de criação na edição)
        final Map<String, dynamic> dadosParaSalvar = {
          'sala': _salaController.text,
          'data': _dataController.text,
          'horario': _horarioController.text,
          'finalidade': _finalidadeController.text,
        };

        if (widget.reservaId == null) {
          // MODO CADASTRO: Adiciona as chaves exclusivas de criação
          dadosParaSalvar['status'] = 'Confirmada';
          dadosParaSalvar['criadoEm'] = FieldValue.serverTimestamp();
          await reservasRef.add(dadosParaSalvar);
        } else {
          // MODO EDIÇÃO: Atualiza apenas os dados no documento existente
          await reservasRef.doc(widget.reservaId).update(dadosParaSalvar);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.reservaId == null 
                  ? 'Reserva salva com sucesso!' 
                  : 'Reserva atualizada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Muda o título dinamicamente com base na ação
    final tituloTela = widget.reservaId == null ? 'Nova Reserva' : 'Editar Reserva';

    return Scaffold(
      appBar: AppBar(
        title: Text(tituloTela),
        backgroundColor: const Color(0xFF0D6EFD),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _salaController,
                decoration: const InputDecoration(labelText: 'Sala/Laboratório'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe a sala da reserva';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dataController,
                decoration: const InputDecoration(labelText: 'Data (ex: 28/05/2026)'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe a data';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _horarioController,
                decoration: const InputDecoration(labelText: 'Horário (ex: 08:00 - 10:00)'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Informe o horário';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _finalidadeController,
                decoration: const InputDecoration(labelText: 'Finalidade (ex: Aula prática)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o propósito da reserva';
                  } else if (value.length < 5) {
                    return 'Seja mais específico na finalidade';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _salvarReserva,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.reservaId == null ? 'Salvar Reserva' : 'Atualizar Reserva'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}