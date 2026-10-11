import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../hafs/hafs_qcf4_pack.dart';
import '../models/mushaf_riwayah.dart';
import '../registration/mushaf_riwayah_registration.dart';
import 'mushaf_assets.dart';

const _hafsAsset = 'packages/mushaf/assets/packs/hafs.zip';
const _warshAsset = 'packages/mushaf/assets/packs/warsh.zip';
const _hafsMarker = 'hafs-qcf4-v4';
const _warshMarker = 'warsh-v1';

/// Unpacks the Hafs and Warsh files shipped with this package.
///
/// A riwayah that was already registered is left as-is, so a host can still
/// point at its own folder before [Mushaf.initialize].
Future<void> installBundledMushafPacks({AssetBundle? bundle}) async {
  final source = bundle ?? rootBundle;
  final support = await getApplicationSupportDirectory();
  final root = Directory('${support.path}/mushaf_packs');

  if (!HafsQcf4Pack.isActive) {
    final dir = await _materialize(
      source,
      asset: _hafsAsset,
      dest: Directory('${root.path}/hafs'),
      marker: _hafsMarker,
    );
    registerMushafHafsQcf4(localRoot: dir.path);
  }
  if (!MushafAssets.isRegistered(MushafRiwayah.warsh)) {
    final dir = await _materialize(
      source,
      asset: _warshAsset,
      dest: Directory('${root.path}/warsh'),
      marker: _warshMarker,
    );
    registerMushafWarsh(localRoot: dir.path);
  }
}

Future<Directory> _materialize(
  AssetBundle bundle, {
  required String asset,
  required Directory dest,
  required String marker,
}) async {
  final ready = File('${dest.path}/.bundled');
  if (await ready.exists()) {
    final stored = (await ready.readAsString()).trim();
    if (stored == marker && await _packLooksReady(dest, marker)) {
      return dest;
    }
  }
  if (await dest.exists()) {
    await dest.delete(recursive: true);
  }
  await dest.create(recursive: true);

  final data = await bundle.load(asset);
  final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  final archive = ZipDecoder().decodeBytes(bytes);
  for (final file in archive) {
    final name = file.name;
    if (name.isEmpty || name.contains('..')) {
      continue;
    }
    final path = '${dest.path}/$name';
    if (!file.isFile) {
      await Directory(path).create(recursive: true);
      continue;
    }
    final out = File(path);
    await out.parent.create(recursive: true);
    await out.writeAsBytes(file.content, flush: true);
  }
  await ready.writeAsString(marker);
  return dest;
}

Future<bool> _packLooksReady(Directory dest, String marker) async {
  if (marker.startsWith('hafs')) {
    return HafsQcf4Pack.looksLikePack(dest.path);
  }
  final warsh = File('${dest.path}/assets/quran/warsh/warsh.json');
  return warsh.exists();
}
