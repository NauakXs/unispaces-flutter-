import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/login_page.dart';
import '../reserva_form_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Função de Logout
  void _sair(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  // Função para excluir a reserva com confirmação de segurança
  void _excluirReserva(BuildContext context, String reservaId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja cancelar e excluir esta reserva? Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Fecha o aviso
              
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('reservas')
                      .doc(reservaId)
                      .delete();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reserva excluída com sucesso!'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao excluir: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UniSpaces - Painel'),
        backgroundColor: const Color(0xFF0D6EFD),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _sair(context),
            tooltip: 'Sair',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logado como: ${user?.email ?? "Email não encontrado"}',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            const Text(
              'Suas Reservas:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('reservas')
                    .orderBy('criadoEm', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return const Center(child: Text('Erro ao carregar reservas.'));
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhuma reserva encontrada.\nToque no botão "+" para criar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                    );
                  }

                  final reservas = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: reservas.length,
                    itemBuilder: (context, index) {
                      final reserva = reservas[index];
                      final data = reserva.data() as Map<String, dynamic>;

                      final sala = data['sala'] ?? 'Sem sala';
                      final dataReserva = data['data'] ?? 'Sem data';
                      final horario = data['horario'] ?? 'Sem horário';
                      final status = data['status'] ?? 'Pendente';

                      final corStatus = status == 'Confirmada' ? Colors.green : Colors.orange;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: corStatus.withValues(alpha: 0.2),
                            child: Icon(Icons.meeting_room, color: corStatus),
                          ),
                          title: Text(
                            sala,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('$dataReserva • $horario\nStatus: $status'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // NOVA AÇÃO DE EDITAR
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReservaFormPage(
                                        reservaId: reserva.id,
                                        dadosAtuais: data,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // AÇÃO DE DELETAR
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _excluirReserva(context, reserva.id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReservaFormPage()),
          );
        },
        backgroundColor: const Color(0xFF0D6EFD),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}