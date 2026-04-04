//
//  EditWordView.swift
//  VocabWithAI
//
//  Created on 2026-03-30
//

import SwiftUI

struct EditWordView: View {
    @StateObject private var viewModel: EditWordViewModel
    @Environment(\.presentationMode) private var presentationMode
    @State private var showDeleteConfirm = false

    init(word: Word) {
        _viewModel = StateObject(wrappedValue: EditWordViewModel(word: word))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer().frame(height: 72)

            fieldSection(label: "단어 (WORD)") {
                TextField("", text: $viewModel.word)
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .submitLabel(.done)
            }

            fieldSection(label: "뜻 (MEANING)") {
                TextField("", text: $viewModel.meaning)
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .submitLabel(.done)
            }

            fieldSection(label: "발음 (선택사항) (PRONUNCIATION)") {
                TextField("", text: $viewModel.pronunciation)
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 18)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .submitLabel(.done)
            }

            fieldSection(label: "메모 (MEMO)") {
                ZStack(alignment: .topLeading) {
                    if viewModel.memo.isEmpty {
                        Text("Enter additional notes")
                            .font(.system(size: 16))
                            .foregroundColor(Color(.placeholderText))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                    }
                    TextEditor(text: $viewModel.memo)
                        .font(.system(size: 16))
                        .frame(height: 150)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .scrollContentBackground(.hidden)
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }

            Spacer()

            saveButton
                .padding(.bottom, 28)
        }
        .padding(.horizontal, 20)
        .overlay(alignment: .top) {
            customNavBar
                .padding(.horizontal, 20)
                .padding(.top, 12)
        }
        .navigationBarHidden(true)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .confirmationDialog("이 단어를 삭제하시겠어요?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("삭제", role: .destructive) {
                if let target = WordRepository.shared.words.first(where: { $0.id == viewModel.originalId }) {
                    WordRepository.shared.deleteWord(target)
                }
                presentationMode.wrappedValue.dismiss()
            }
            Button("취소", role: .cancel) {}
        }
    }

    private var customNavBar: some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(8)
                    .contentShape(Rectangle())
            }
            Spacer()
            Text("Edit Word")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
            Spacer()
            Button(action: { showDeleteConfirm = true }) {
                Image(systemName: "trash")
                    .font(.system(size: 18))
                    .foregroundColor(.black)
                    .padding(8)
                    .contentShape(Rectangle())
            }
        }
        .padding(.vertical, 8)
        .background(Color(.white))
    }

    private func fieldSection<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
            content()
        }
    }

    private var saveButton: some View {
        Button(action: {
            viewModel.save()
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack(spacing: 8) {
                Text("수정 완료")
                    .font(.system(size: 18, weight: .semibold))
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(viewModel.isSaveEnabled ? Color.blue : Color.blue.opacity(0.4))
            .cornerRadius(16)
        }
        .disabled(!viewModel.isSaveEnabled)
    }
}

// MARK: - Preview
struct EditWordView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            EditWordView(word: Word(
                word: "猫",
                meaning: "고양이",
                pronunciation: "ねこ",
                memo: ""
            ))
        }
    }
}
