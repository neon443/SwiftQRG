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
			
			SavedQRCodeTabView(
				savedQRCodes: $savedQRCodes,
				qrCodeImage: $qrCodeImage,
				urlInput: $urlInput
			)
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
		
		if let outputImage = filter.outputImage {
			let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
				.colored(using: selectedForegroundColor, backgroundColor: selectedBackgroundColor)
			if let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) {
				qrCodeImage = UIImage(cgImage: cgImage)
			}
		}
	}
	
	func shuffleColor() {
		selectedForegroundColor = Color(
			red: Double.random(in: 0...1),
			green: Double.random(in: 0...1),
			blue: Double.random(in: 0...1)
		)
		selectedBackgroundColor = Color(
			red: Double.random(in: 0...1),
			green: Double.random(in: 0...1),
			blue: Double.random(in: 0...1)
		)
		generateQRCode(from: urlInput)
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
				Text("QR Code will appear here")
					.font(.headline)
			}
			
			List {
				QRCodeSettingsView(
					urlInput: $urlInput,
					selectedProtocol: $selectedProtocol,
					selectedForegroundColor: $selectedForegroundColor,
					selectedBackgroundColor: $selectedBackgroundColor,
					generateQRCode: generateQRCode,
					shuffleColors: shuffleColor
				)
				
				QRCodeCustomizationView(rounded: $rounded)
			}
			
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
	var shuffleColors: () -> Void
	
	var body: some View {
		VStack {
			HStack {
				TextField("Enter a URL", text: $urlInput)
					.onChange(of: urlInput) { _ in
						shuffleColors()
						generateQRCode(urlInput)
					}
					.textFieldStyle(RoundedBorderTextFieldStyle())
				
				Button(action: {
					if let clipboardString = UIPasteboard.general.string {
						urlInput = clipboardString
						generateQRCode(clipboardString)
					}
				}) {
					Image(systemName: "doc.on.clipboard")
						.font(.title)
						.foregroundColor(.blue)
				}
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
			
			Button(action: shuffleColors) {
				Label("Shuffle Colors", systemImage: "shuffle")
					.padding()
					.background(Color.blue)
					.foregroundColor(.white)
					.cornerRadius(10)
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
		.pickerStyle(SegmentedPickerStyle())
	}
}

struct SaveButtonView: View {
	var saveQRCodeManually: () -> Void
	
	var body: some View {
		Button("Save QR", action: saveQRCodeManually)
			.buttonStyle(RoundedButtonStyle(backgroundColor: .green, foregroundColor: .white))
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
			
			Button("Clear All") {
				savedQRCodes.removeAll()
				UserDefaults.standard.removeObject(forKey: "SavedQRCodes")
			}
			.buttonStyle(RoundedButtonStyle(backgroundColor: .red, foregroundColor: .white))
		}
	}
}

struct SavedQRCode: Identifiable, Codable {
	var id = UUID()
	var imageData: Data
	var text: String
	
	var image: UIImage {
		UIImage(data: imageData) ?? UIImage()
	}
	
	init(image: UIImage, text: String) {
		self.imageData = image.pngData() ?? Data()
		self.text = text
	}
}

extension CIImage {
	func colored(using foregroundColor: Color, backgroundColor: Color) -> CIImage {
		let foregroundCIColor = CIColor(color: UIColor(foregroundColor))
		let backgroundCIColor = CIColor(color: UIColor(backgroundColor))
		return self.applyingFilter("CIFalseColor", parameters: [
			"inputColor0": foregroundCIColor,
			"inputColor1": backgroundCIColor
		])
	}
}

struct RoundedButtonStyle: ButtonStyle {
	var backgroundColor: Color
	var foregroundColor: Color
	
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.padding()
			.background(backgroundColor)
			.foregroundColor(foregroundColor)
			.cornerRadius(10)
			.scaleEffect(configuration.isPressed ? 0.95 : 1.0)
	}
}

#Preview {
	ContentView()
}
