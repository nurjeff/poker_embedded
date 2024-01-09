import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';
import 'package:poker_at_juergen/network_manager.dart';

class Resolver {
  Future<bool> findMulticast() async {
    String? foundUrl;
    const String name = '_workstation._tcp';

    final MDnsClient client = MDnsClient();
    await client.start();

    await for (final PtrResourceRecord ptr in client
        .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(name))) {
      await for (final SrvResourceRecord srv
          in client.lookup<SrvResourceRecord>(
              ResourceRecordQuery.service(ptr.domainName))) {
        if (srv.name.contains("raspberrypoker")) {
          foundUrl = await resolveMdnsService(srv.target, srv.port);
          if (foundUrl != null) {
            NetworkManager().host = foundUrl;
            client.stop();
            return true;
          } else {
            foundUrl =
                await resolveMdnsService(srv.target.split('.').first, srv.port);
            if (foundUrl != null) {
              NetworkManager().host = foundUrl;
              client.stop();
              return true;
            }
          }
          continue;
        }
      }
    }
    client.stop();

    return false;
  }

  Future<String?> resolveMdnsService(String serviceTarget, int port) async {
    try {
      String hostname = serviceTarget.split(':')[0];

      List<InternetAddress> addresses = await InternetAddress.lookup(hostname);
      if (addresses.isNotEmpty) {
        String ipAddress = addresses.first.address;
        String url = 'http://$ipAddress:49267/api/v1/poker';
        return url;
      } else {
        print('No addresses found for $serviceTarget');
        return null;
      }
    } catch (e) {
      print('Failed to resolve $serviceTarget: $e');
      return null;
    }
  }
}
