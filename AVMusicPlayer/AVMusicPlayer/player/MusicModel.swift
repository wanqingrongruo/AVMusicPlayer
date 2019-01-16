//
//  File.swift
//  blackboard
//
//  Created by roni on 2018/12/26.
//  Copyright © 2018 xkb. All rights reserved.
//

import Foundation
import UIKit

public extension Array {
    public subscript(safe index: Int) -> Element? {
        return indices ~= index ? self[index] : .none
    }
}

struct MusicModel: Codable {
    var id: Int
    var title: String
    var artist: String
    var pic: String
    var musicUrl: URL
    var fileName: String
    var content: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case artist = "artist"
        case pic = "pic"
        case musicUrl = "music_url"
        case fileName = "file_name"
        case content = "content"
    }
}

struct MusicList: Codable {
    let data: [MusicModel]
}

func generateMusicList() -> MusicList {
    let data = musicList.data(using: .utf8)!
    let decoder = JSONDecoder()
    let list = try! decoder.decode(MusicList.self, from: data)
    return list
}

let musicList = """
{
"data": [
{
"id": 1,
"title": "我是真的爱过你",
"artist": "刘增瞳",
"pic": "https://upload-images.jianshu.io/upload_images/565029-fffe612148783b7a.jpg",
"music_url" : "https://link.hhtjim.com/163/509512959.mp3",
"file_name" : "说不出的回忆",
"content": "别再说我变了 谁想伪装自己 谁能看见我夜里无助"
},
{
"id": 2,
"title": "下一站茶山刘",
"artist": "房东的猫",
"pic": "https://upload-images.jianshu.io/upload_images/565029-fffe612148783b7a.jpg",
"music_url" : "https://link.hhtjim.com/163/486188245.mp3",
"file_name" : "拾贰",
"content": "时间 像武汉六月的大雨"
},
{
"id": 3,
"title": "そばにいるね",
"artist": "青山黛玛",
"pic": "https://upload-images.jianshu.io/upload_images/565029-fffe612148783b7a.jpg",
"music_url" : "https://link.hhtjim.com/163/555142.mp3",
"file_name" : "そばにいるね",
"content": "そばにいるね"
},
{
"id": 4,
"title": "二零三",
"artist": "毛不易",
"pic": "https://upload-images.jianshu.io/upload_images/565029-fffe612148783b7a.jpg",
"music_url" : "https://link.hhtjim.com/163/547170991.mp3",
"file_name" : "翻唱",
"content": "致十年后的自己，人生能有几个十年"
},
{
"id": 5,
"title": "爱情废柴",
"artist": "周杰伦",
"pic": "https://upload-images.jianshu.io/upload_images/565029-fffe612148783b7a.jpg",
"music_url" : "http://roni.oss-cn-shanghai.aliyuncs.com/%E5%91%A8%E6%9D%B0%E4%BC%A6%20-%20%E5%91%8A%E7%99%BD%E6%B0%94%E7%90%83.flac",
"file_name" : "床边故事flac",
"content": "致十年后的自己，人生能有几个十年"
},
{
"id": 6,
"title": "绝代风华",
"artist": "许嵩",
"pic": "https://upload-images.jianshu.io/upload_images/565029-fffe612148783b7a.jpg",
"music_url" : "http://roni.oss-cn-shanghai.aliyuncs.com/%E7%BB%9D%E4%BB%A3%E9%A3%8E%E5%8D%8E.m4r",
"file_name" : "绝代风华m4r",
"content": "致十年后的自己，人生能有几个十年"
},
{
"id": 7,
"title": "明智之举",
"artist": "许嵩",
"pic": "https://upload-images.jianshu.io/upload_images/565029-fffe612148783b7a.jpg",
"music_url" : "http://roni.oss-cn-shanghai.aliyuncs.com/%E8%AE%B8%E5%B5%A9%20-%20%E6%98%8E%E6%99%BA%E4%B9%8B%E4%B8%BE.mp3",
"file_name" : "寻宝游戏mp3",
"content": "致十年后的自己，人生能有几个十年"
},
{
"id": 8,
"title": "光年之外",
"artist": "邓紫棋",
"pic": "https://upload-images.jianshu.io/upload_images/565029-fffe612148783b7a.jpg",
"music_url" : "https://link.hhtjim.com/163/547170991.mp3",
"file_name" : "太空旅客mp3",
"content": "致十年后的自己，人生能有几个十年"
}
]
}
"""
