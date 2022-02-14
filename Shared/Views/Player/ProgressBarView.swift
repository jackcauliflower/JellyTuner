//
//  ProgressBar.swift
//  Music
//
//  Created by Jack Caulfield on 10/15/21.
//

import SwiftUI

struct ProgressBarView: View {
    private let totalHeight = CGFloat(30)
    @State private var prog: CGFloat = 0
    @State private var progNoAnim: CGFloat = 0
    @State private var resetPlayer: Bool = false
    @ObservedObject var player = Player.shared
    private let seekSize: CGFloat = 25
    @State private var seekStart: CGFloat = 0
    @State private var offset: CGFloat = -(25 / 2)
    @State private var elapsedOffset: CGFloat = 0
    @State private var durationOffset: CGFloat = 0
    @State private var canAnimate: Bool = false
    @State private var appeared: Bool = false
    
    private let refreshRateHelper: RefreshRateHelper = RefreshRateHelper.shared
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
 
    var body: some View {
            GeometryReader { geometry in
                VStack(spacing: 1){
                    
                    ZStack(alignment: .leading) {
                        Rectangle().frame(width: geometry.size.width, height: 3)
                            .opacity(0.0)
                        Rectangle().fill(Color.clear).background(
                            Rectangle().frame(width: geometry.size.width - seekSize, height: 3)
                                .foregroundColor(Color.primary).opacity(0.5)
                                .cornerRadius(1.5)
                        ).padding(.horizontal, seekSize / 2)
                        Rectangle().fill(Color.clear).frame(width: max(min(prog, progNoAnim), 0)).background(
                            Rectangle().frame(height: 3)
                                .foregroundColor(Color.accentColor)
                                .cornerRadius(1.5)
                        ).padding(.horizontal, seekSize / 2)
                        .animation(Animation.linear(duration: Globals.playTimeInterval), value: canAnimate ? prog : nil)
                        Circle().fill(Color.black.opacity(0.0001))
                            .overlay(
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: player.seeking ? seekSize : 10, height: player.seeking ? seekSize : 10)
                                .animation(.easeInOut(duration: 0.2), value: player.seeking)
                            )
                        .frame(width: seekSize, height: seekSize)
                        .offset(x:min(min(prog, progNoAnim), geometry.size.width), y: 0)
                            .animation(Animation.linear(duration: Globals.playTimeInterval), value: canAnimate ? prog : nil)
                            .onAppear{
                                prog = (CGFloat(player.playProgress > 1 ? 1 : player.playProgress)*(geometry.size.width - seekSize))
                                progNoAnim = prog
                                appeared = true
                            }
                        .onReceive(player.$trigger){ _ in
                                let temp = (CGFloat(player.playProgressAhead > 1 ? 1 : player.playProgressAhead)*(geometry.size.width - seekSize))
                                if canAnimate {
                                    if (temp > prog) || resetPlayer {
                                        progNoAnim = temp
                                        prog = temp
                                        resetPlayer = false
                                    }else{
                                        resetPlayer = true
                                        progNoAnim = temp
                                    }
                                }else{
                                    if appeared{
                                        canAnimate = true
                                    }
                                }
                        }
                        .gesture(DragGesture()
                                    .onChanged { gesture in
                            
                            refreshRateHelper.preferredFrameRateRange(.init(minimum: 80, maximum: 120, __preferred: 120))
                                        if !player.seeking{
                                            player.seeking = true
                                            seekStart = prog
                                        }
                                        let temp = seekStart + gesture.translation.width
                                        if temp >= offset && temp <= geometry.size.width - seekSize{
                                            let progress = Double((seekStart + gesture.translation.width)/(geometry.size.width - seekSize))
                                            player.setTimeElapsed(progress: Double((progress < 0 ? 0 : progress > 1 ? 1 : progress)))
                                        }

                                    }
                                    .onEnded { gesture in
                                        let realProgress = (prog/(geometry.size.width - seekSize))
                                        player.seek(progress: Double(realProgress))
                            
                            refreshRateHelper.preferredFrameRateRange(.default)
                                    }
                        )
                    }
                    HStack{
                        Text(player.timeElasped)
                            .frame(width: 50, height: nil, alignment: .leading)
                            .offset(y: elapsedOffset)
                            // .animation(.linear(duration: 0.25), value: elapsedOffset)
                        Spacer()
                        Text("\(player.timeRemaining)")
                            .frame(width: 50, height: nil, alignment: .trailing)
                            .offset(y: durationOffset)
//                            .animation(.linear(duration: 0.25), value: durationOffset)
                    }
//                    .onReceive(player.$playProgressAhead, perform: { _ in
//                            if prog < 50 && player.seeking{
//                                elapsedOffset = -7.5
//                            }else{
//                                    elapsedOffset = -7.5
//                            }
//                            if prog > geometry.size.width - seekSize - 50 && player.seeking {
//                                durationOffset = -7.5
//                            }else{
//                                    durationOffset = -7.5
//                            }
//                    })
                    .foregroundColor(Color.primary)
                    .padding(.horizontal, seekSize / 2)
                    .font(.system(size: 13))
                    
                }
            }.frame(height:totalHeight)
    }
}
