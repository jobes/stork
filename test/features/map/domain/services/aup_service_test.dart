import 'package:flutter_test/flutter_test.dart';
import 'package:stork/features/map/data/services/cze_aup_service.dart';
import 'package:stork/features/map/data/services/svk_aup_service.dart';
import 'package:stork/features/map/data/utils/aup_parsing.dart';
import 'package:stork/features/map/domain/models/airspace_activity_status.dart';
import 'package:stork/features/map/domain/models/openaip_unit.dart';
import 'package:stork/features/map/domain/models/reference_datum.dart';

void main() {
  group('AUP limit parsing', () {
    test('parses GND / SFC as ground level', () {
      final gnd = parseAupLimit('GND');
      expect(gnd, isNotNull);
      expect(gnd!.value, 0.0);
      expect(gnd.unit, OpenAipUnit.meters);
      expect(gnd.referenceDatum, ReferenceDatum.gnd);
    });

    test('parses flight levels', () {
      final fl = parseAupLimit('FL95');
      expect(fl, isNotNull);
      expect(fl!.value, 95.0);
      expect(fl.unit, OpenAipUnit.flightLevel);
      expect(fl.referenceDatum, ReferenceDatum.std);

      final flSpaced = parseAupLimit('FL 120');
      expect(flSpaced!.value, 120.0);
    });

    test('parses Czech flight levels (F095 = FL95)', () {
      final fl = parseAupLimit('F095');
      expect(fl, isNotNull);
      expect(fl!.value, 95.0);
      expect(fl.unit, OpenAipUnit.flightLevel);
      expect(fl.referenceDatum, ReferenceDatum.std);

      expect(parseAupLimit('F420')!.value, 420.0);
    });

    test('parses feet and meters', () {
      final ft = parseAupLimit('9500FT AMSL');
      expect(ft!.value, 9500.0);
      expect(ft.unit, OpenAipUnit.feet);
      expect(ft.referenceDatum, ReferenceDatum.msl);

      final m = parseAupLimit('2500M');
      expect(m!.value, 2500.0);
      expect(m.unit, OpenAipUnit.meters);
    });

    test('returns null for UNL / NOTAM / garbage', () {
      expect(parseAupLimit('UNL'), isNull);
      expect(parseAupLimit('NOTAM'), isNull);
      expect(parseAupLimit(null), isNull);
      expect(parseAupLimit('xyz'), isNull);
    });
  });

  group('AirspaceActivityStatus parsing', () {
    test('maps payload tokens', () {
      expect(
        AirspaceActivityStatus.fromPayload('ACTIVE'),
        AirspaceActivityStatus.active,
      );
      expect(
        AirspaceActivityStatus.fromPayload('DEACTIVATED'),
        AirspaceActivityStatus.inactive,
      );
      expect(
        AirspaceActivityStatus.fromPayload('unknown-token'),
        AirspaceActivityStatus.unknown,
      );
      expect(
        AirspaceActivityStatus.fromPayload(null),
        AirspaceActivityStatus.unknown,
      );
    });
  });

  group('SvkAupService parsing (LzPS GIS)', () {
    test('parses an ArcGIS FeatureServer response as active airspaces', () {
      const body = '''
      {
        "exceededTransferLimit": false,
        "features": [
          {"attributes": {"airspace": "LZR28"}},
          {"attributes": {"airspace": "LZR225"}},
          {"attributes": {"airspace": "LZTRA3"}}
        ],
        "fields": [
          {"name": "airspace", "type": "esriFieldTypeString"}
        ],
        "geometryType": "esriGeometryPolygon"
      }
      ''';

      final result = SvkAupService.parseLzpsGisResponse(body);

      expect(result, hasLength(3));
      expect(result[0].designator, 'LZR28');
      expect(result[0].name, 'LZR28');
      expect(result[0].status, AirspaceActivityStatus.active);
      expect(result[0].source, 'SVK_LZPS');
      // The GIS query only returns active reservations without a window.
      expect(result[0].validFrom, isNull);
      expect(result[0].validTo, isNull);
    });

    test('ignores features without an airspace attribute', () {
      const body = '''
      {
        "features": [
          {"attributes": {"airspace": "LZR1"}},
          {"attributes": {"other": "x"}},
          {"attributes": {"airspace": "   "}}
        ]
      }
      ''';

      final result = SvkAupService.parseLzpsGisResponse(body);

      expect(result, hasLength(1));
      expect(result.first.designator, 'LZR1');
    });

    test('returns empty list for invalid payloads', () {
      expect(SvkAupService.parseLzpsGisResponse('not json'), isEmpty);
      expect(SvkAupService.parseLzpsGisResponse('42'), isEmpty);
      expect(SvkAupService.parseLzpsGisResponse('[]'), isEmpty);
      expect(
        SvkAupService.parseLzpsGisResponse('{"features": "nope"}'),
        isEmpty,
      );
    });
  });

  group('CzeAupService parsing (ŘLP aup.rlp.cz)', () {
    const indexHtml = '''
    <HTML><BODY>
    <UL>
    <LI><A HREF="data/aup_04082026.htm"> Platný AUP</A> (od 04.08.2026 06:00 UTC do 05.08.2026 06:00 UTC)</LI>
    <DL>
    <DD> -&nbsp; <A HREF="data/uup_04082026_0846_3060680796.htm"> Platný UUP</A> (od 04.08.2026 08:46 UTC do 05.08.2026 06:00 UTC)</DD>
    <DD> -&nbsp; <A HREF="data/uup_04082026_1304_1097994229.htm"> Platný UUP</A> (od 04.08.2026 13:04 UTC do 05.08.2026 06:00 UTC)</DD>
    </DL>
    <LI><A HREF="data/aup_05082026.htm"> Následující AUP</A> (od 05.08.2026 06:00 UTC do 06.08.2026 06:00 UTC)</LI>
    </UL>
    </BODY></HTML>
    ''';

    const aupHtml = '''
    <HTML>
    <HEAD><META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=windows-1250"></HEAD>
    <BODY>
    <TR><TD class="title1">Plan vyuzivani vzdusneho prostoru Ceske republiky </TD></TR>
    <TR><TD class="title1">OD 04. 08. 2026 06:00 DO 05. 08. 2026 06:00 </TD></TR>
    <TR><TD class="title2">  Datum a cas vydani:       03. 08. 2026 11:22:03</TD></TR>
    <TR><TH class="titlex">C/ Prostory spravovane AMC (AMA) : </TH></TR>
    <TR><TD class="expl">P.c.</TD><TD class="expl">Prostor</TD><TD class="expl">Spodni hran.</TD><TD class="expl">Horni hran.</TD><TD class="expl">Od</TD><TD class="expl">Do</TD><TD class="expl">Zodp.stanoviste</TD><TD class="expl">Dopl.info</TD></TR>
    <TR><TD class="data">1.</TD><TD class="data">TSA2</TD><TD class="data">GND</TD><TD class="data">F095</TD><TD class="data">06:00</TD><TD class="data">20:00</TD><TD class="data">ARMY</TD><TD class="data">OAT</TD></TR>
    <TR><TD class="data">2.</TD><TD class="data">TRA12</TD><TD class="data">GND</TD><TD class="data">5000FT/AMSL</TD><TD class="data">13:00</TD><TD class="data">22:00</TD><TD class="data">LKNA</TD><TD class="data">OAT</TD></TR>
    <TR><TH class="titlex">D/ Prostory nespravovane AMC (NAM) : </TH></TR>
    </BODY></HTML>
    ''';

    const preDawnHtml = '''
    <HTML><BODY>
    <TR><TD class="title1">OD 04. 08. 2026 06:00 DO 05. 08. 2026 06:00 </TD></TR>
    <TR><TH class="titlex">C/ Prostory spravovane AMC (AMA) : </TH></TR>
    <TR><TD class="data">1.</TD><TD class="data">TRA7</TD><TD class="data">F095</TD><TD class="data">F155</TD><TD class="data">05:00</TD><TD class="data">05:59</TD><TD class="data">LKKT</TD><TD class="data">PJE</TD></TR>
    <TR><TH class="titlex">D/ Prostory nespravovane AMC (NAM) : </TH></TR>
    </BODY></HTML>
    ''';

    const midnightHtml = '''
    <HTML><BODY>
    <TR><TD class="title1">OD 04. 08. 2026 06:00 DO 05. 08. 2026 06:00 </TD></TR>
    <TR><TH class="titlex">C/ Prostory spravovane AMC (AMA) : </TH></TR>
    <TR><TD class="data">1.</TD><TD class="data">TRA8</TD><TD class="data">GND</TD><TD class="data">F155</TD><TD class="data">24:00</TD><TD class="data">24:00</TD><TD class="data">LKKT</TD><TD class="data">PJE</TD></TR>
    <TR><TH class="titlex">D/ Prostory nespravovane AMC (NAM) : </TH></TR>
    </BODY></HTML>
    ''';

    const uupHtml = '''
    <HTML><BODY>
    <TR><TD class="title1">OD 04. 08. 2026 13:04 DO 05. 08. 2026 06:00 </TD></TR>
    <TR><TD class="title2">  Datum a cas vydani:       04. 08. 2026 13:04:26</TD></TR>
    <TR><TH class="titlex">C/ Prostory spravovane AMC (AMA) : </TH></TR>
    <TR><TD class="data">12.</TD><TD class="data">TRA56</TD><TD class="data">1000FT/AGL</TD><TD class="data">F125</TD><TD class="data">07:00</TD><TD class="data">16:00</TD><TD class="data">---</TD><TD class="data">CNL</TD></TR>
    <TR><TD class="data">13.</TD><TD class="data">TRA62</TD><TD class="data">3000FT/AMSL</TD><TD class="data">F245</TD><TD class="data">12:00</TD><TD class="data">18:38</TD><TD class="data">LKVO</TD><TD class="data">OAT</TD></TR>
    <TR><TH class="titlex">D/ Prostory nespravovane AMC (NAM) : </TH></TR>
    </BODY></HTML>
    ''';

    test('parses the valid AUP and its UUP updates from the index', () {
      final index = CzeAupService.parseAupIndex(indexHtml);

      expect(index, isNotNull);
      expect(index!.aup, 'aup_04082026.htm');
      expect(index.uups, [
        'uup_04082026_0846_3060680796.htm',
        'uup_04082026_1304_1097994229.htm',
      ]);
    });

    test('returns null when the index has no valid AUP', () {
      expect(CzeAupService.parseAupIndex('<html>no links</html>'), isNull);
      expect(CzeAupService.parseAupIndex(''), isNull);
    });

    test('parses the AUP validity window', () {
      final validity = CzeAupService.parseAupValidity(aupHtml);

      expect(validity, isNotNull);
      expect(validity!.validFrom, DateTime.utc(2026, 8, 4, 6));
      expect(validity.validTo, DateTime.utc(2026, 8, 5, 6));
    });

    test('parses an AUP document into active airspace activations', () {
      final result = CzeAupService.parseAupDocument(aupHtml, isUup: false);

      expect(result, hasLength(2));
      // Designators are mapped to the openAIP form (`TSA2` -> `LKTSA2`).
      expect(result[0].designator, 'LKTSA2');
      expect(result[0].name, 'LKTSA2');
      expect(result[0].status, AirspaceActivityStatus.active);
      expect(result[0].source, CzeAupService.sourceCodeValue);
      expect(result[0].lowerLimit!.value, 0);
      expect(result[0].upperLimit!.value, 95);
      expect(result[0].upperLimit!.unit, OpenAipUnit.flightLevel);
      expect(result[0].validFrom, DateTime.utc(2026, 8, 4, 6));
      expect(result[0].validTo, DateTime.utc(2026, 8, 4, 20));
      expect(result[1].designator, 'LKTRA12');
      expect(result[1].validFrom, DateTime.utc(2026, 8, 4, 13));
      expect(result[1].validTo, DateTime.utc(2026, 8, 4, 22));
    });

    test('windows before the day boundary belong to the last validity day', () {
      final result = CzeAupService.parseAupDocument(preDawnHtml, isUup: false);

      expect(result, hasLength(1));
      expect(result.first.designator, 'LKTRA7');
      expect(result.first.validFrom, DateTime.utc(2026, 8, 5, 5));
      expect(result.first.validTo, DateTime.utc(2026, 8, 5, 5, 59));
    });

    test('accepts 24:00 as the end of the day', () {
      final result = CzeAupService.parseAupDocument(midnightHtml, isUup: false);

      expect(result, hasLength(1));
      expect(result.first.designator, 'LKTRA8');
      expect(result.first.validFrom, DateTime.utc(2026, 8, 5));
      expect(result.first.validTo, DateTime.utc(2026, 8, 6));
    });

    test('UUP rows with CNL cancel, other rows update the activation', () {
      final result = CzeAupService.parseAupDocument(
        uupHtml,
        isUup: true,
        dayWindow: CzeAupService.parseAupValidity(aupHtml),
      );

      expect(result, hasLength(2));
      expect(result[0].designator, 'LKTRA56');
      expect(result[0].status, AirspaceActivityStatus.inactive);
      // UUP times resolve against the AUP day, not the UUP issue time.
      expect(result[0].validFrom, DateTime.utc(2026, 8, 4, 7));
      expect(result[0].validTo, DateTime.utc(2026, 8, 4, 16));
      expect(result[1].designator, 'LKTRA62');
      expect(result[1].status, AirspaceActivityStatus.active);
    });

    test('returns empty list for invalid payloads', () {
      expect(CzeAupService.parseAupDocument('not html', isUup: false), isEmpty);
      expect(CzeAupService.parseAupDocument('', isUup: false), isEmpty);
      expect(
        CzeAupService.parseAupDocument(
          '<HTML>no validity, no sections</HTML>',
          isUup: false,
        ),
        isEmpty,
      );
    });
  });
}
