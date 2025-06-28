// lib/services/attachment_image_cache_service.dart
import 'dart:typed_data';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:fieldx_fsm/services/enhanced_service_adapters.dart';

class AttachmentImageCacheService {
  // Singleton instance
  static final AttachmentImageCacheService _instance = AttachmentImageCacheService._internal();
  factory AttachmentImageCacheService() => _instance;
  AttachmentImageCacheService._internal();
  
  // In-memory cache of images
  final Map<String, Uint8List> _imageCache = {};
  
  // Check if an image is in the cache
  bool hasImage(String attachmentId) {
    return _imageCache.containsKey(attachmentId);
  }
  
  // Get an image from the cache
  Uint8List? getImage(String attachmentId) {
    return _imageCache[attachmentId];
  }
  
  // Cache a new image
  void cacheImage(String attachmentId, Uint8List imageData) {
    _imageCache[attachmentId] = imageData;
    print("✅ Cached image for attachment ID: $attachmentId (${imageData.length} bytes)");
  }
  
  // Clear the cache
  void clearCache() {
    _imageCache.clear();
    print("🧹 Image cache cleared");
  }
  
  // Get correct image URL for an attachment ID
  // In AttachmentImageCacheService class
  static String getImageUrlForAttachment(String baseUrl, String attachmentId) {
    return '$baseUrl/?entryPoint=image&id=$attachmentId';
  }
  
  // Load an image by ID (either from cache or from network)
  Future<Uint8List?> loadImage(String baseUrl, String attachmentId, Map<String, String> headers) async {
    // Check cache first
    if (hasImage(attachmentId)) {
      return getImage(attachmentId);
    }
    
    // Not in cache, load from network
    try {
      final url = getImageUrlForAttachment(baseUrl, attachmentId);
      final response = await http.get(Uri.parse(url), headers: headers);
      
      if (response.statusCode == 200) {
        cacheImage(attachmentId, response.bodyBytes);
        return response.bodyBytes;
      } else {
        print("❌ Failed to load image: $attachmentId (Status: ${response.statusCode})");
        return null;
      }
    } catch (e) {
      print("❌ Error loading image: $attachmentId - $e");
      return null;
    }
  }
  
  // Prefetch images for a list of appointment details
  Future<void> prefetchImagesForAppointments(List<Map<String, dynamic>> appointments) async {
    print("🔄 Starting prefetch of images for ${appointments.length} appointments");
    
    try {
      final baseUrl = await AppointmentService.baseUrl;
      print("🔹 Using base URL: $baseUrl");
      
      final headers = await AppointmentService.authHeaders;
      print("🔹 Auth headers ready with keys: ${headers.keys.join(', ')}");
      
      int fetchedCount = 0;
      int errorCount = 0;
      int skippedCount = 0;
      
      for (final appointment in appointments) {
        // Check if appointment has attachmentfbIds
        final attachmentIds = appointment['attachmentfbIds'];
        if (attachmentIds == null || attachmentIds is! List || attachmentIds.isEmpty) {
          continue;
        }
        
        print("🔹 Found ${attachmentIds.length} attachments for appointment: ${appointment['id']}");
        
        // Fetch each attachment
        for (final attachmentId in attachmentIds) {
          final idStr = attachmentId.toString();
          if (hasImage(idStr)) {
            skippedCount++;
            continue; // Skip if already cached
          }
          
          try {
            final url = getImageUrlForAttachment(baseUrl, idStr);
            print("🔄 Fetching image: $url");
            
            final response = await http.get(Uri.parse(url), headers: headers);
            
            if (response.statusCode == 200) {
              print("✅ Successfully fetched image: $idStr (${response.bodyBytes.length} bytes)");
              cacheImage(idStr, response.bodyBytes);
              fetchedCount++;
            } else {
              print("❌ Failed to fetch image: $idStr (Status: ${response.statusCode})");
              errorCount++;
            }
          } catch (e) {
            print("❌ Error fetching image: $idStr - $e");
            errorCount++;
          }
        }
      }
      
      print("✅ Prefetch complete: $fetchedCount images cached, $skippedCount skipped, $errorCount errors");
    } catch (e) {
      print("❌ Error in prefetchImagesForAppointments: $e");
    }
  }

  // Prefetch specific attachment IDs
  Future<void> prefetchAttachmentIds(List<String> attachmentIds) async {
    print("🔄 Starting prefetch of ${attachmentIds.length} specific attachments");
    if (attachmentIds.isNotEmpty) {
      print("🔹 First few IDs: ${attachmentIds.take(min(5, attachmentIds.length)).join(', ')}");
    }
    
    try {
      final baseUrl = await AppointmentService.baseUrl;
      print("🔹 Using base URL: $baseUrl");
      
      final headers = await AppointmentService.authHeaders;
      print("🔹 Auth headers ready with keys: ${headers.keys.join(', ')}");
      
      int fetchedCount = 0;
      int errorCount = 0;
      int skippedCount = 0;
      
      for (final attachmentId in attachmentIds) {
        if (hasImage(attachmentId)) {
          skippedCount++;
          continue; // Skip if already cached
        }
        
        try {
          final url = getImageUrlForAttachment(baseUrl, attachmentId);
          print("🔄 Fetching image: $url");
          
          final response = await http.get(Uri.parse(url), headers: headers);
          
          if (response.statusCode == 200) {
            print("✅ Successfully fetched image: $attachmentId (${response.bodyBytes.length} bytes)");
            cacheImage(attachmentId, response.bodyBytes);
            fetchedCount++;
          } else {
            print("❌ Failed to fetch image: $attachmentId (Status: ${response.statusCode})");
            errorCount++;
          }
        } catch (e) {
          print("❌ Error fetching image: $attachmentId - $e");
          errorCount++;
        }
      }
      
      print("✅ Prefetch complete: $fetchedCount images cached, $skippedCount skipped, $errorCount errors");
    } catch (e) {
      print("❌ Error in prefetchAttachmentIds: $e");
    }
  }
}