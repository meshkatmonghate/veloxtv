import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';

class RecordingService {
  final List<RecordingTask> _tasks = [];
  final Map<String, http.Client> _activeClients = {};

  List<RecordingTask> get tasks => List.unmodifiable(_tasks);

  Future<RecordingTask> startRecording({
    required String channelName,
    required String streamUrl,
  }) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final recDir = Directory('${docsDir.path}/VeloxTV/Recordings');
    if (!await recDir.exists()) {
      await recDir.create(recursive: true);
    }

    final safeName = channelName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${recDir.path}/${safeName}_$timestamp.ts';

    final task = RecordingTask(
      id: 'rec_$timestamp',
      channelName: channelName,
      streamUrl: streamUrl,
      filePath: filePath,
      startTime: DateTime.now(),
      isActive: true,
    );

    _tasks.insert(0, task);

    final client = http.Client();
    _activeClients[task.id] = client;

    // Start background download stream
    _recordStream(task, client);

    return task;
  }

  void _recordStream(RecordingTask task, http.Client client) async {
    try {
      final request = http.Request('GET', Uri.parse(task.streamUrl));
      final response = await client.send(request);

      final file = File(task.filePath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        if (!task.isActive) break;
        sink.add(chunk);
        task.totalBytes += chunk.length;
      }

      await sink.flush();
      await sink.close();
    } catch (_) {
      // Stream stopped or cancelled
    } finally {
      task.isActive = false;
      task.endTime = DateTime.now();
      _activeClients.remove(task.id);
    }
  }

  void stopRecording(String taskId) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      task.isActive = false;
      task.endTime = DateTime.now();

      final client = _activeClients[taskId];
      client?.close();
      _activeClients.remove(taskId);
    }
  }

  Future<void> deleteRecording(String taskId) async {
    stopRecording(taskId);
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final file = File(task.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      _tasks.removeAt(taskIndex);
    }
  }
}
