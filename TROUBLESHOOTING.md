# 🔧 WhisperLAN Peer Discovery Troubleshooting

## 🚨 Common Issues & Solutions

### Issue: App Not Asking for Local Network Permission
- **Problem**: The app doesn't prompt for Local Network access
- **Solution**: 
  - The app now includes a **robust Local Network permission request system**
  - **First launch**: Permission screen appears automatically with both permissions
  - **Subsequent launches**: Only shows if microphone permission is missing
  - **Local Network permission**: Now properly triggers the iOS system permission dialog
  - **How it works**: Uses both MCNearbyServiceAdvertiser and MCNearbyServiceBrowser to ensure permission request
  - **If permission doesn't appear**: Tap "Request All Permissions" to force the system dialogs
  - **Alternative**: Tap "Skip for Now" then restart the app to try again
  - **Settings check**: After granting permissions, check Settings > Privacy & Security > Local Network

### Issue: Devices Not Discovering Each Other

#### 1. **Check Device Proximity**
- **Problem**: Devices are too far apart
- **Solution**: Ensure devices are within **10 meters (33 feet)** of each other
- **Test**: Move devices closer together

#### 2. **Verify Bluetooth & Wi-Fi**
- **Problem**: Bluetooth or Wi-Fi is disabled
- **Solution**: 
  - Go to **Settings > Bluetooth** - Turn ON
  - Go to **Settings > Wi-Fi** - Turn ON
  - Both must be enabled for MultipeerConnectivity

#### 3. **Check App Permissions**
- **Problem**: App doesn't have required permissions
- **Solution**:
  - Go to **Settings > Privacy & Security > Local Network**
  - Find "WhisperLAN" and ensure it's **ON**
  - Go to **Settings > Privacy & Security > Microphone**
  - Find "WhisperLAN" and ensure it's **ON**

#### 4. **Restart Discovery Process**
- **Problem**: Discovery gets stuck
- **Solution**:
  1. On both devices, tap **"Stop Hosting"** and **"Stop Searching"**
  2. Wait 5 seconds
  3. On Device A: Tap **"Start Hosting"**
  4. On Device B: Tap **"Search"**
  5. Wait 10-30 seconds for discovery

#### 5. **Check iOS Version Compatibility**
- **Problem**: iOS version issues
- **Solution**: Ensure both devices are running **iOS 15.0 or later**

#### 6. **Restart Apps**
- **Problem**: App state issues
- **Solution**:
  1. Force quit both apps (swipe up and swipe away)
  2. Restart both apps
  3. Try discovery again

#### 7. **Check Device Settings**
- **Problem**: Device-specific settings blocking discovery
- **Solution**:
  - Go to **Settings > General > AirDrop**
  - Set to **"Everyone"** or **"Contacts Only"**
  - Go to **Settings > General > AirPlay & Handoff**
  - Ensure **"Handoff"** is ON

## 🔍 Using the Debug Console

### Step-by-Step Debug Process

1. **Open Debug Tab**
   - Launch WhisperLAN on both devices
   - Tap the **"Debug"** tab (ladybug icon)

2. **Start Discovery**
   - **Device A**: Tap **"Start Hosting"** in Peers tab
   - **Device B**: Tap **"Search"** in Peers tab

3. **Monitor Debug Messages**
   - Look for these messages:
     - ✅ `"Starting to host..."` / `"Starting to browse for peers..."`
     - ✅ `"Now hosting - device should be discoverable"`
     - ✅ `"Now browsing for peers..."`
     - ❌ Any messages containing `"ERROR"`

4. **Expected Debug Output**
   ```
   [Device A - Hosting]
   [timestamp] PeerManager initialized with peer ID: iPhone-1234567890
   [timestamp] Starting to host...
   [timestamp] Now hosting - device should be discoverable
   
   [Device B - Searching]
   [timestamp] PeerManager initialized with peer ID: iPhone-0987654321
   [timestamp] Starting to browse for peers...
   [timestamp] Now browsing for peers...
   [timestamp] Found peer: iPhone-1234567890
   [timestamp] Added peer to discovered list: iPhone-1234567890
   ```

## 🚨 Error Messages & Solutions

### "ERROR: Failed to start advertising"
- **Cause**: Bluetooth/Wi-Fi disabled or permission denied
- **Solution**: Check Bluetooth, Wi-Fi, and Local Network permissions

### "ERROR: Failed to start browsing"
- **Cause**: Bluetooth/Wi-Fi disabled or permission denied
- **Solution**: Check Bluetooth, Wi-Fi, and Local Network permissions

### "ERROR: Failed to start browsing: The operation couldn't be completed. (NSNetServicesErrorDomain error -72008.)"
- **Cause**: Bonjour service discovery conflict or network service issue
- **Solution**: 
  1. **Network Monitoring**: The app now includes real-time network status monitoring
  2. **Enhanced Retry Logic**: Automatic retry with exponential backoff (3-5 second delays)
  3. **Network Validation**: Check the Debug tab for network interface status
  4. **Restart Discovery**: Stop and restart the discovery process
  5. **Check Network**: Ensure both devices are on the same Wi-Fi network
  6. **Restart Apps**: Force quit and restart both apps
  7. **Wait for Retry**: The app now automatically retries failed discovery with longer delays

### "Invalid serviceType passed to MCNearbyServiceAdvertiser"
- **Cause**: Service type doesn't meet MultipeerConnectivity requirements
- **Solution**: 
  1. **Service Type Rules**: Must be 1-15 characters, alphanumeric and hyphens only
  2. **Current Service**: The app uses `whisperlan` (valid format)
  3. **Validation**: Added runtime validation to catch invalid service types early

### No "Found peer" messages
- **Cause**: Devices too far apart or discovery not working
- **Solution**: Move devices closer, restart discovery process

### "ERROR: Could not find peer to invite"
- **Cause**: Peer disappeared from discovered list
- **Solution**: Wait for peer to be rediscovered, then try again

## 📱 Device-Specific Issues

### iPhone Issues
- **Problem**: Personal Hotspot interfering
- **Solution**: Turn OFF Personal Hotspot temporarily

### iPad Issues
- **Problem**: iPad Pro with M1/M2 chip settings
- **Solution**: Check **Settings > General > AirPlay & Handoff**

### Multiple Devices
- **Problem**: Too many devices trying to connect
- **Solution**: Limit to 2-3 devices at once (MultipeerConnectivity limit is 8)

## 🔄 Advanced Troubleshooting

### Reset Network Settings
1. Go to **Settings > General > Transfer or Reset iPhone**
2. Tap **"Reset"**
3. Tap **"Reset Network Settings"**
4. Restart device
5. Re-enable Bluetooth and Wi-Fi

### Check for Interference
- **Problem**: Other devices or networks interfering
- **Solution**: 
  - Move away from crowded Wi-Fi networks
  - Turn off other Bluetooth devices temporarily
  - Test in a quiet environment

### Test with Different Devices
- **Problem**: Specific device compatibility issues
- **Solution**: Try with different iPhone models to isolate the issue

## ✅ Success Checklist

Before testing, ensure:

- [ ] Both devices are within 10 meters
- [ ] Bluetooth is ON on both devices
- [ ] Wi-Fi is ON on both devices
- [ ] Local Network permission granted
- [ ] Microphone permission granted
- [ ] Both devices running iOS 15.0+
- [ ] Apps are freshly launched
- [ ] No Personal Hotspot active
- [ ] Debug console shows no errors

## 📞 Still Having Issues?

If you're still experiencing problems:

1. **Check Debug Console** for specific error messages
2. **Try different devices** to isolate the issue
3. **Test in different locations** to rule out interference
4. **Restart both devices** completely
5. **Check iOS version** on both devices

The debug console will provide real-time information about what's happening during the discovery process, making it much easier to identify and resolve issues. 