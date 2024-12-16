//
//  ContentView.swift
//  SwiftQRG
//
//  Created by Nihaal Sharma on 05/12/2024.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ContentView: View {
	@State private var qrCodeImage: UIImage? = nil
	@State private var urlInput: String = ""
	@State private var selectedForegroundColor: Color = .black
	@State private var selectedBackgroundColor: Color = .white
	@State private var selectedProtocol: String = "https"
	@State private var rounded: Bool = false
	
	@State private var savedQRCodes: [SavedQRCode] = []
	
	private let context = CIContext()
	private let filter = CIFilter.qrCodeGenerator()

	var body: some View {
		TabView {
			QRGeneratorTabView(
				qrCodeImage: $qrCodeImage,
				urlInput: $urlInput,
				selectedForegroundColor: $selectedForegroundColor,
				selectedBackgroundColor: $selectedBackgroundColor,
				selectedProtocol: $selectedProtocol,
				rounded: $rounded,
				generateQRCode: generateQRCode,
				shuffleColor: shuffleColor,
				saveQRCodeManually: saveQRCodeManually
			)
			.tabItem {
				Label("QR Generator", systemImage: "qrcode")
			}
			.onAppear {
				loadSavedQRCodes()
			}
			
			SavedQRCodeTabView(savedQRCodes: $savedQRCodes, qrCodeImage: $qrCodeImage, urlInput: $urlInput)
				.tabItem {
					Label("Saved QR Codes", systemImage: "folder")
				}
		}
	}
	
	func generateQRCode(from string: String) {
		let fullURL = "\(selectedProtocol)://\(string)"
		guard let data = fullURL.data(using: .utf8), !string.isEmpty else {
			qrCodeImage = nil
			return
		}
		filter.setValue(data, forKey: "inputMessage")
		
		let foregroundCIColor = CIColor(color: UIColor(selectedForegroundColor))
		let backgroundCIColor = CIColor(color: UIColor(selectedBackgroundColor))
		filter.setValue(foregroundCIColor, forKey: "inputColor0")
		filter.setValue(backgroundCIColor, forKey: "inputColor1")
		
		if let outputImage = filter.outputImage {
			let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
			if let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) {
				qrCodeImage = UIImage(cgImage: cgImage)
			}
		}
	}
	
	func shuffleColor() {
		let colors: [Color] = [.red, .green, .blue, .orange, .purple, .yellow]
		selectedForegroundColor = colors.randomElement() ?? .black
	}
	
	func saveQRCodeManually() {
		guard let qrCodeImage = qrCodeImage else { return }
		saveQRCode(qrCodeImage, text: urlInput)
	}
	
	func saveQRCode(_ qrCode: UIImage, text: String) {
		let savedQRCode = SavedQRCode(image: qrCode, text: text)
		savedQRCodes.append(savedQRCode)
		UserDefaults.standard.set(try? PropertyListEncoder().encode(savedQRCodes), forKey: "SavedQRCodes")
	}
	
	func loadSavedQRCodes() {
		if let savedData = UserDefaults.standard.data(forKey: "SavedQRCodes"),
		   let savedList = try? PropertyListDecoder().decode([SavedQRCode].self, from: savedData) {
			savedQRCodes = savedList
		}
	}
}

struct QRGeneratorTabView: View {
	@Binding var qrCodeImage: UIImage?
	@Binding var urlInput: String
	@Binding var selectedForegroundColor: Color
	@Binding var selectedBackgroundColor: Color
	@Binding var selectedProtocol: String
	@Binding var rounded: Bool
	
	var generateQRCode: (String) -> Void
	var shuffleColor: () -> Void
	var saveQRCodeManually: () -> Void
	
	var body: some View {
		VStack(spacing: 20) {
			if let qrCodeImage = qrCodeImage {
				Image(uiImage: qrCodeImage)
					.resizable()
					.interpolation(.none)
					.scaledToFit()
					.frame(width: 250, height: 250)
					.clipShape(RoundedRectangle(cornerRadius: rounded ? 20 : 0))
			} else {
				Text("QR Code")
					.font(.headline)
			}
			
			List {
				QRCodeSettingsView(
					urlInput: $urlInput,
					selectedProtocol: $selectedProtocol,
					selectedForegroundColor: $selectedForegroundColor,
					selectedBackgroundColor: $selectedBackgroundColor,
					generateQRCode: generateQRCode,
					shuffleColor: shuffleColor
				)
				
				QRCodeCustomizationView(
					rounded: $rounded
				)
			}
			.padding(.top, 10)
			
			SaveButtonView(saveQRCodeManually: saveQRCodeManually)
		}
	}
}

struct QRCodeSettingsView: View {
	@Binding var urlInput: String
	@Binding var selectedProtocol: String
	@Binding var selectedForegroundColor: Color
	@Binding var selectedBackgroundColor: Color
	
	var generateQRCode: (String) -> Void
	var shuffleColor: () -> Void
	
	var body: some View {
		VStack {
			HStack {
				ProtocolPicker(
					selectedProtocol: $selectedProtocol,
					generateQRCode: generateQRCode
				)
				URLInputTextField(
					urlInput: $urlInput,
					generateQRCode: generateQRCode
				)
//				PasteButton(
//					selectedForegroundColor: $selectedForegroundColor,
//					urlInput: $urlInput,
//					generateQRCode: generateQRCode
//				)
				PasteButton(
					selectedColor: $selectedBackgroundColor,
					urlInput: $urlInput,
					generateQRCode: generateQRCode
				)
			}
			
			HStack {
				ColorPicker("Foreground Color", selection: $selectedForegroundColor)
					.onChange(of: selectedForegroundColor) { _ in
						generateQRCode(urlInput)
					}
				
				ColorPicker("Background Color", selection: $selectedBackgroundColor)
					.onChange(of: selectedBackgroundColor) { _ in
						generateQRCode(urlInput)
					}
			}
			
			HStack {
				ShuffleButton(selectedColor: $selectedForegroundColor, shuffleColor: shuffleColor)
			}
		}
	}
}

struct QRCodeCustomizationView: View {
	@Binding var rounded: Bool
	
	var body: some View {
		Picker("Corners", selection: $rounded) {
			Text("Square").tag(false)
			Text("Rounded").tag(true)
		}
		.pickerStyle(.segmented)
	}
}

struct SaveButtonView: View {
	var saveQRCodeManually: () -> Void
	
	var body: some View {
		HStack {
			Button(action: saveQRCodeManually) {
				Text("Save QR")
					.padding()
					.background(Color.green)
					.foregroundColor(.white)
					.cornerRadius(10)
			}
		}
		.padding(.top)
	}
}

struct ProtocolPicker: View {
	@Binding var selectedProtocol: String
	var generateQRCode: (String) -> Void
	
	var body: some View {
		Picker("", selection: $selectedProtocol) {
			Text("HTTPS").tag("https")
			Text("HTTP").tag("http")
			Text("None").tag("")
		}
		.onChange(of: selectedProtocol) { _ in
			generateQRCode(selectedProtocol)
		}
		.fixedSize()
	}
}

struct URLInputTextField: View {
	@Binding var urlInput: String
	var generateQRCode: (String) -> Void
	
	var body: some View {
		TextField("Enter a URL", text: $urlInput)
			.onChange(of: urlInput) { _ in
				generateQRCode(urlInput)
			}
	}
}

struct SavedQRCode: Identifiable, Codable {
	var id = UUID()
	var imageData: Data
	var text: String
	
	var image: UIImage {
		return UIImage(data: imageData) ?? UIImage()
	}
	
	init(image: UIImage, text: String) {
		self.imageData = image.pngData() ?? Data()
		self.text = text
	}
}
struct PasteButton: View {
	@Binding var selectedColor: Color
	@Binding var urlInput: String
	var generateQRCode: (String) -> Void
	
	var body: some View {
		Button(action: {
			if let clipboardString = UIPasteboard.general.string {
				urlInput = clipboardString
				generateQRCode(clipboardString)
			}
		}) {
			Image(systemName: "doc.on.clipboard")
				.font(.title)
				.foregroundColor(selectedColor)
		}
	}
}

struct ShuffleButton: View {
	@Binding var selectedColor: Color
	var shuffleColor: () -> Void
	
	var body: some View {
		Button(action: shuffleColor) {
			Image(systemName: "shuffle")
				.font(.title)
				.foregroundColor(selectedColor)
		}
	}
}

struct SavedQRCodeTabView: View {
	@Binding var savedQRCodes: [SavedQRCode]
	@Binding var qrCodeImage: UIImage?
	@Binding var urlInput: String
	
	var body: some View {
		VStack {
			Text("Saved QR Codes")
				.font(.title)
				.padding()
			
			List {
				ForEach(savedQRCodes) { savedQRCode in
					HStack {
						Image(uiImage: savedQRCode.image)
							.resizable()
							.scaledToFit()
							.frame(width: 50, height: 50)
							.clipShape(RoundedRectangle(cornerRadius: 10))
						
						Text(savedQRCode.text)
							.lineLimit(1)
							.truncationMode(.tail)
					}
					.onTapGesture {
						urlInput = savedQRCode.text
						qrCodeImage = savedQRCode.image
					}
				}
				.onMove { indices, newOffset in
					savedQRCodes.move(fromOffsets: indices, toOffset: newOffset)
					UserDefaults.standard.set(try? PropertyListEncoder().encode(savedQRCodes), forKey: "SavedQRCodes")
				}
				.onDelete { indices in
					savedQRCodes.remove(atOffsets: indices)
					UserDefaults.standard.set(try? PropertyListEncoder().encode(savedQRCodes), forKey: "SavedQRCodes")
				}
			}
			
			ClearAllButton(savedQRCodes: $savedQRCodes)
		}
	}
}

struct ClearAllButton: View {
	@Binding var savedQRCodes: [SavedQRCode]
	
	var body: some View {
		Button(action: clearAllQRCodes) {
			Text("Clear All")
				.padding()
				.background(Color.red)
				.foregroundColor(.white)
				.cornerRadius(10)
		}
	}
	
	func clearAllQRCodes() {
		savedQRCodes.removeAll()
		UserDefaults.standard.removeObject(forKey: "SavedQRCodes")
	}
}

#Preview {
	ContentView()
}
