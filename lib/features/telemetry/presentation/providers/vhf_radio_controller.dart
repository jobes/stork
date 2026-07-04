import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stork/core/services/cannelloni_service_io.dart';
import 'package:stork/core/native/dronecan/vhf_radio_control.dart';

part 'vhf_radio_controller.g.dart';

@riverpod
class VhfRadioController extends _$VhfRadioController {
  @override
  void build() {
    // Stateless controller
  }

  Future<void> _sendControlRequest({
    required int nodeId,
    required int radioInstance,
    required int action,
    int level = 0,
    int index = 0,
    int frequencyKhz = 0,
    String frequencyName = '',
  }) async {
    final cannelloni = ref.read(cannelloniServiceProvider.notifier);
    final req = VhfRadioControlRequest(
      radioInstance: radioInstance,
      action: action,
      level: level,
      index: index,
      frequencyKhz: frequencyKhz,
      frequencyName: frequencyName,
    );

    final res = await cannelloni.sendRequest(
      destinationNodeId: nodeId,
      dataTypeId: VhfRadioControlRequest.messageId,
      dataTypeSignature: VhfRadioControlRequest.messageSignature,
      payload: req.toPayload(),
    );

    final response = VhfRadioControlResponse.fromPayload(res);
    if (response.status != VhfRadioControlResponse.statusOk) {
      throw Exception("Chyba DroneCAN požiadavky (status: ${response.status})");
    }
  }

  Future<void> setActiveFrequency({
    required int nodeId,
    required int radioInstance,
    required int frequencyKhz,
    required String name,
  }) async {
    await _sendControlRequest(
      nodeId: nodeId,
      radioInstance: radioInstance,
      action: VhfRadioControlRequest.actionSetActiveFreq,
      frequencyKhz: frequencyKhz,
      frequencyName: name,
    );
  }

  Future<void> setStandbyFrequency({
    required int nodeId,
    required int radioInstance,
    required int frequencyKhz,
    required String name,
  }) async {
    await _sendControlRequest(
      nodeId: nodeId,
      radioInstance: radioInstance,
      action: VhfRadioControlRequest.actionSetStandbyFreq,
      frequencyKhz: frequencyKhz,
      frequencyName: name,
    );
  }

  Future<void> flipFrequencies({
    required int nodeId,
    required int radioInstance,
  }) async {
    await _sendControlRequest(
      nodeId: nodeId,
      radioInstance: radioInstance,
      action: VhfRadioControlRequest.actionFlip,
    );
  }

  Future<void> toggleDualWatch({
    required int nodeId,
    required int radioInstance,
  }) async {
    await _sendControlRequest(
      nodeId: nodeId,
      radioInstance: radioInstance,
      action: VhfRadioControlRequest.actionDualToggle,
    );
  }

  Future<void> setVolume(int nodeId, int radioInstance, int level) async {
    await _sendControlRequest(
      nodeId: nodeId,
      radioInstance: radioInstance,
      action: VhfRadioControlRequest.actionSetVolume,
      level: level,
    );
  }

  Future<void> setSquelch(int nodeId, int radioInstance, int level) async {
    await _sendControlRequest(
      nodeId: nodeId,
      radioInstance: radioInstance,
      action: VhfRadioControlRequest.actionSetSquelch,
      level: level,
    );
  }

  Future<void> setVox(int nodeId, int radioInstance, int level) async {
    await _sendControlRequest(
      nodeId: nodeId,
      radioInstance: radioInstance,
      action: VhfRadioControlRequest.actionSetVox,
      level: level,
    );
  }

  Future<void> setIntercom(int nodeId, int radioInstance, int level) async {
    await _sendControlRequest(
      nodeId: nodeId,
      radioInstance: radioInstance,
      action: VhfRadioControlRequest.actionSetIntercom,
      level: level,
    );
  }

  Future<void> setMicGain(int nodeId, int radioInstance, int index, int level) async {
    await _sendControlRequest(
      nodeId: nodeId,
      radioInstance: radioInstance,
      action: VhfRadioControlRequest.actionSetMicGain,
      index: index,
      level: level,
    );
  }
}
