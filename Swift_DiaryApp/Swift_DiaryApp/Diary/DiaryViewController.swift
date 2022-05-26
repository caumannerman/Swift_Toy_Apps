//
//  DiaryViewController.swift
//  Swift_DiaryApp
//
//  Created by 양준식 on 2022/05/23.
//

import UIKit
import SnapKit
//일기장 작성 후 저장을 위한 protocol
protocol WriteDiaryDelegate: AnyObject {
    func didSelectRegister(diary: Diary)
}

final class DiaryViewController: UIViewController {
    
    private var diaryList = [Diary](){
        //새로운 등록 혹은 수정, 삭제가 일어날 때마다 userDefaults와 동기화!
        didSet{ self.saveDiaryList()
            debugPrint("didset 호출!")
            print(diaryList)
        }
    }
    
    private lazy var newButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(pushtoWriteDiary))
        return button
    }()
    
    @objc func pushtoWriteDiary(){
        let vc = WriteDiaryViewController()
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        //contentsView 내부 view들의 간격 조정
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 20
        //section의 padding즉, inset값을 지정해준다. 
        layout.sectionInset = UIEdgeInsets(top: 12.0, left: 10.0, bottom: 12.0, right: 10.0)
        layout.scrollDirection = .vertical
        //collectionView사용을 위해 초기 설정 - layout, Cell들의 간격, delegate, dataSource
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.register(DiaryCollectionViewCell.self, forCellWithReuseIdentifier: "DiaryCollectionViewCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    // DiaryList에 있는 Diary들을 딕셔너리 형태로 바꾸어 UserDefaults에 저장!
    private func saveDiaryList(){
        let date = self.diaryList.map{
            [
                "uuid": $0.uuid,
                "title": $0.title,
                "contents": $0.contents,
                "date": $0.date,
                "isStar": $0.isStar
            ]
        }
        //userDefaults에 저장!!
        UserDefaults.standard.set(date, forKey: "diaryList")
    }
    
    //userDefaults에서 불러올 때는 , Dictionary형태에 고차함수를 사용해서 Diary 객체의 List로 받아온다.
    // 앱 첫 실행시에 사용하는 함수 딱 그 뿐(앱 첫 실행시, 이전 데이터들을 userDefualts에서 불러와야하므로!!)
    //이후에는 사용 X
    private func loadDiaryList() {
        let userDefaults = UserDefaults.standard
        //object메서드는 Any타입으로 리턴해주기 때문에 타입캐스팅 해줘야함
        guard let data = userDefaults.object(forKey: "diaryList") as? [[String: Any]] else {return}
        //compactMap이 List형태로 반환
        self.diaryList = data.compactMap{
            //compactMap 안에서 옵셔널 바인딩 해줘야함!
            guard let uuid = $0["uuid"] as? String else { return nil }
            guard let title = $0["title"] as? String else { return nil }
            guard let contents = $0["contents"] as? String else { return nil }
            guard let date = $0["date"] as? Date else { return nil }
            guard let isStar = $0["isStar"] as? Bool else { return nil}
            return Diary(uuid: uuid, title: title, contents: contents, date: date, isStar: isStar)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        //새 일기 추가 버튼을 navigationBar에 추가
        self.navigationItem.rightBarButtonItem = newButton
        loadDiaryList()
        // editDiary 이벤트가 일어났을 때
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(editDiaryNotification(_:)),
            name: NSNotification.Name("editDiary"),
            object: nil)
        //starDiary이벤트 발생 시
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(starDiaryNotification(_:)),
            name: NSNotification.Name("starDiary"),
            object: nil)
        // 삭제 이벤트가 일어났을 때
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(deleteDiaryNotification(_:)),
            name: NSNotification.Name("deleteDiary"),
            object: nil)
    }
    
    @objc func editDiaryNotification(_ notification: Notification) {
        //수정되어 돌아온 diary!!
        guard let diary = notification.object as? Diary else { return }
        //notification으로 받아온 uuid와 같은 uuid를 가진 diary의 index를 가져옴
        guard let index = self.diaryList.firstIndex(where: { $0.uuid == diary.uuid }) else { return }
        //수정되어 온 diary를 넣어준다
        self.diaryList[index] = diary
        self.diaryList = self.diaryList.sorted(by: {
            $0.date.compare($1.date) == .orderedDescending
        })
        //화면에 새로 뿌려줌
        self.collectionView.reloadData()
    }
    @objc func starDiaryNotification(_ notification: Notification){
        //받아온 dictionary에서 정보를을 빼고, isStar부분만 수정해준다.
        //해당 diary 찾기는 uuid를 사용!
        guard let starDiary = notification.object as? [String: Any] else { return }
        guard let isStar = starDiary["isStar"] as? Bool else {return}
        guard let uuid = starDiary["uuid"] as? String else { return }
        guard let index = self.diaryList.firstIndex(where: { $0.uuid == uuid}) else { return}
        self.diaryList[index].isStar = isStar
        // 일기장 목록 화면에서 isStar여부가 표현되지 않으므로 reloadData()하지 않아도 됨
    }
    @objc func deleteDiaryNotification(_ notification: Notification){
        guard let uuid = notification.object as? String else { return }
        guard let index = self.diaryList.firstIndex(where: { $0.uuid == uuid}) else { return}
        self.diaryList.remove(at: index)
        //List상태와 화면의 상태를 맞춰줘야하므로, 화면의 collectionView에서도 삭제해준다.
        /////self.collectionView.reloadData()해줘도 되지만, deleteItems해주는 것이 효율적!!
        self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
    }
    
    private func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy년 MM월 dd일(EEEEE)"
        formatter.locale = Locale(identifier: "ko_KR")
        //지정해준 dateFormat대로 string을 반환
        return formatter.string(from: date)
    }
}


extension DiaryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.diaryList.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DiaryCollectionViewCell", for: indexPath) as? DiaryCollectionViewCell else { return UICollectionViewCell() }
        let diary = self.diaryList[indexPath.row]
        cell.setup(with: diary)
//        cell.titleLabel.text = self.diaryList[indexPath.row].title
//        cell.dateLabel.text = self.dateToString(diaryList[indexPath.row].date)
        return cell
    }
    
}

extension DiaryViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (UIScreen.main.bounds.width / 2) - 20, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = DiaryDetailViewController()
        let diary = self.diaryList[indexPath.row]
        vc.configureDiary( diary, indexPath)

        self.navigationController?.pushViewController(vc, animated: true)
     
        
    }
}


extension DiaryViewController: WriteDiaryDelegate {
    func didSelectRegister(diary: Diary) {
        self.diaryList.append(diary)
        //날짜  순 정렬
        //최신순으로 정렬 되도록
        self.diaryList = self.diaryList.sorted(by: {
            $0.date.compare($1.date) == .orderedDescending
        })
        self.collectionView.reloadData()
    }
}

private extension DiaryViewController{
    func setupLayout(){
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints{
            $0.top.bottom.leading.trailing.equalToSuperview()
        }
    }
}
