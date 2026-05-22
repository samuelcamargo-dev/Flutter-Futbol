import 'dart:convert'; // Necesario para transformar el texto de la API a JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Importamos la librería de internet

void main() {
  runApp(const MiAppFutbol());
}

// El contenedor principal de nuestra aplicación
class MiAppFutbol extends StatelessWidget {
  const MiAppFutbol({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mi App de Fútbol',
      theme: ThemeData(
        primarySwatch: Colors.green, // Color verde futbolero para el botón/barra
      ),
      home: const PantallaPartidos(),
    );
  }
}

// Esta pantalla tiene estado (Stateful) porque va a cargar datos de internet
class PantallaPartidos extends StatefulWidget {
  const PantallaPartidos({super.key});

  @override
  State<PantallaPartidos> createState() => _PantallaPartidosState();
}

class _PantallaPartidosState extends State<PantallaPartidos> {
  final String miToken = '2a5414f4e96e4b318dc83432d113e4eb';

  // Esta función va a internet, busca los partidos y los devuelve en una Lista
  Future<List<dynamic>> consultarPartidos() async {
    final url = Uri.parse('https://api.football-data.org/v4/competitions/PL/matches?limit=10');

    // Hacemos la petición GET incluyendo el Token que te pide la documentación
    final respuesta = await http.get(
      url,
      headers: {'X-Auth-Token': miToken},
    );

    // Si la respuesta es correcta (Código 200 Ok)
    if (respuesta.statusCode == 200) {
      final datosDecodificados = jsonDecode(respuesta.body);
      return datosDecodificados['matches']; // Devolvemos solo la lista de partidos
    } else {
      // Si falla (por ejemplo, si el token está mal)
      throw Exception('Error al conectar con la API: ${respuesta.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partidos de la Premier League'),
        backgroundColor: Colors.green,
      ),
      // El FutureBuilder se encarga de escuchar a "consultarPartidos" y redibujar la pantalla solo
      body: FutureBuilder<List<dynamic>>(
        future: consultarPartidos(),
        builder: (context, snapshot) {
          // 1. Mientras está cargando, muestra el círculo de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          // 2. Si hubo un error (falta de internet, token inválido...), muestra el error
          else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Ocurrió un problema: ${snapshot.error}'),
              ),
            );
          }
          
          // 3. Si no trae datos o la lista está vacía
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No se encontraron partidos.'),
            );
          }

          // 4. Si todo salió bien, guardamos los partidos en una variable
          final listaDePartidos = snapshot.data!;

          // Dibujamos la lista en la pantalla usando widgets super básicos
          return ListView.builder(
            itemCount: listaDePartidos.length,
            itemBuilder: (context, index) {
              final partido = listaDePartidos[index];

              // Extraemos los datos que nos interesan del mapa JSON
              final String equipoLocal = partido['homeTeam']['name'];
              final String equipoVisitante = partido['awayTeam']['name'];
              final String estado = partido['status'];
              
              // Los goles pueden venir vacíos (null) si el partido no ha empezado
              final golesLocal = partido['score']['fullTime']['home'] ?? '-';
              final golesVisitante = partido['score']['fullTime']['away'] ?? '-';

              // Retornamos una tarjeta visual para cada partido
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // <-- Corregido: Ahora solo hay un padding instalado aquí
                  child: Column(
                    children: [
                      // Fila para mostrar: Local vs Visitante
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Nombre Equipo Local
                          Expanded(
                            child: Text(
                              equipoLocal,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          // Marcador
                          Text(
                            ' $golesLocal - $golesVisitante ',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          ),
                          // Nombre Equipo Visitante
                          Expanded(
                            child: Text(
                              equipoVisitante,
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8), // Un pequeño espacio
                      // Texto inferior con el estado del partido
                      Text(
                        'Estado: $estado',
                        style: TextStyle(
                          fontSize: 12, 
                          color: estado == 'LIVE' ? Colors.red : Colors.grey
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}