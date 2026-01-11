//
//  ImageManager.swift
//  BookMarker
//
//  Created by Reimos on 10/27/25.
//

import UIKit

/// 이미지 파일 저장/로드를 관리하는 매니저
final class ImageManager {

    static let shared = ImageManager()

    private init() {}

    // MARK: - Constants

    /// 이미지 저장 폴더명
    private let imagesFolderName = "PlaceImages"

    /// 이미지 압축 품질 (0.0 ~ 1.0)
    private let compressionQuality: CGFloat = 0.8

    // MARK: - Directory Paths

    /// Documents 디렉토리 경로
    private var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// PlaceImages 폴더 경로
    private var imagesDirectory: URL {
        return documentsDirectory.appendingPathComponent(imagesFolderName)
    }

    // MARK: - Public Methods

    /// 이미지를 로컬에 저장하고 파일명 반환
    /// - Parameters:
    ///   - image: 저장할 UIImage
    ///   - identifier: 고유 식별자 (예: placeId)
    /// - Returns: 저장된 파일명 (성공 시), nil (실패 시)
    func saveImage(_ image: UIImage, identifier: String) -> String? {
        // PlaceImages 폴더 생성 (없으면)
        createImagesDirectoryIfNeeded()

        // 파일명 생성: place_12345.jpg
        let fileName = "place_\(identifier).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)

        // UIImage → JPEG Data
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            print("ImageManager: JPEG 변환 실패")
            return nil
        }

        do {
            // 파일 저장
            try imageData.write(to: fileURL)
            print("ImageManager: 이미지 저장 성공 - \(fileName)")
            return fileName
        } catch {
            print("ImageManager: 이미지 저장 실패 - \(error.localizedDescription)")
            return nil
        }
    }

    /// 파일명으로 이미지 로드
    /// - Parameter fileName: 파일명 (예: "place_12345.jpg")
    /// - Returns: UIImage (성공 시), nil (실패 시)
    func loadImage(fileName: String) -> UIImage? {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)

        // 파일이 존재하는지 확인
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("ImageManager: 파일이 존재하지 않음 - \(fileName)")
            return nil
        }

        // Data → UIImage
        do {
            let imageData = try Data(contentsOf: fileURL)
            guard let image = UIImage(data: imageData) else {
                print("ImageManager: UIImage 변환 실패 - \(fileName)")
                return nil
            }
            print("ImageManager: 이미지 로드 성공 - \(fileName)")
            return image
        } catch {
            print("ImageManager: 이미지 로드 실패 - \(error.localizedDescription)")
            return nil
        }
    }

    /// 이미지 파일 삭제
    /// - Parameter fileName: 삭제할 파일명 (예: "place_12345.jpg")
    /// - Returns: 성공 여부
    @discardableResult
    func deleteImage(fileName: String) -> Bool {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)

        // 파일이 존재하는지 확인
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("ImageManager: 삭제할 파일이 존재하지 않음 - \(fileName)")
            return false
        }

        do {
            try FileManager.default.removeItem(at: fileURL)
            print("ImageManager: 이미지 삭제 성공 - \(fileName)")
            return true
        } catch {
            print("ImageManager: 이미지 삭제 실패 - \(error.localizedDescription)")
            return false
        }
    }

    /// 이미지 파일이 존재하는지 확인
    /// - Parameter fileName: 확인할 파일명
    /// - Returns: 존재 여부
    func imageExists(fileName: String) -> Bool {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    // MARK: - Private Methods

    /// PlaceImages 디렉토리 생성 (없으면)
    private func createImagesDirectoryIfNeeded() {
        let fileManager = FileManager.default

        // 이미 존재하면 return
        if fileManager.fileExists(atPath: imagesDirectory.path) {
            return
        }

        do {
            try fileManager.createDirectory(
                at: imagesDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            print("ImageManager: PlaceImages 폴더 생성 성공")
        } catch {
            print("ImageManager: PlaceImages 폴더 생성 실패 - \(error.localizedDescription)")
        }
    }
}
