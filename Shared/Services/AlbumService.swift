//
//  AlbumService.swift
//  FinTune
//
//  Created by Jack Caulfield on 10/10/21.
//

import Foundation
import CoreData
import JellyfinAPI

class AlbumService : JellyfinService {
    
    static let shared = AlbumService()
    
//    let artistService = ArtistService.shared
    
    let songService = SongService.shared
        
    func retrieveAlbums(artist: Artist?, complete: @escaping () -> Void) {
//
        ItemsAPI.getItemsByUserId(userId: self.userId, maxOfficialRating: nil, hasThemeSong: nil, hasThemeVideo: nil, hasSubtitles: nil, hasSpecialFeature: nil, hasTrailer: nil, adjacentTo: nil, parentIndexNumber: nil, hasParentalRating: nil, isHd: nil, is4K: nil, locationTypes: nil, excludeLocationTypes: nil, isMissing: nil, isUnaired: nil, minCommunityRating: nil, minCriticRating: nil, minPremiereDate: nil, minDateLastSaved: nil, minDateLastSavedForUser: nil, maxPremiereDate: nil, hasOverview: nil, hasImdbId: nil, hasTmdbId: nil, hasTvdbId: nil, excludeItemIds: nil, startIndex: nil, limit: nil, recursive: true, searchTerm: nil, sortOrder: nil, parentId: nil, fields: nil, excludeItemTypes: nil, includeItemTypes: ["MusicAlbum"], filters: nil, isFavorite: nil, mediaTypes: nil, imageTypes: nil, sortBy: nil, isPlayed: nil, genres: nil, officialRatings: nil, tags: nil, years: nil, enableUserData: true, imageTypeLimit: nil, enableImageTypes: nil, person: nil, personIds: nil, personTypes: nil, studios: nil, artists: nil, excludeArtistIds: nil, artistIds: [artist?.jellyfinId ?? ""], albumArtistIds: nil, contributingArtistIds: nil, albums: nil, albumIds: nil, ids: nil, videoTypes: nil, minOfficialRating: nil, isLocked: nil, isPlaceHolder: nil, hasOfficialRating: nil, collapseBoxSetItems: nil, minWidth: nil, minHeight: nil, maxWidth: nil, maxHeight: nil, is3D: nil, seriesStatus: nil, nameStartsWithOrGreater: nil, nameStartsWith: nil, nameLessThan: nil, studioIds: nil, genreIds: nil, enableTotalRecordCount: nil, enableImages: nil, apiResponseQueue: JellyfinAPI.apiResponseQueue)
            .sink(receiveCompletion: { completion in
                print(completion)
            }, receiveValue: { response in
                if response.items != nil {
                    response.items!.map({ albumResult -> Void in
                                                
                        let album = Album(context: JellyfinService.context)
                        
                        album.jellyfinId = albumResult.id!
                        album.name = albumResult.name!
                        album.productionYear = Int16(albumResult.productionYear ?? 0)
                        
                        if (artist != nil) {
                            album.addToAlbumArtists(artist!)
                        }
                        self.songService.retrieveSongs(parentId: album.jellyfinId!, complete: { songResults in
                                        
                            for songResult in songResults {
                                let song = Song(context: JellyfinService.context)
                                
                                song.jellyfinId = songResult.id
                                song.name = songResult.name
                                song.indexNumber = Int16(songResult.indexNumber!)
                                
                                song.album = album
                                
                                if (album.albumArtists != nil) {
                                    song.addToArtists(album.albumArtists!)
                                }

                                ImageAPI.getItemImage(itemId: albumResult.id!, imageType: .primary)
                                    .sink(receiveCompletion: { completion in
                                        print("Album art retrieval \(completion)")
                                    }, receiveValue: { response in
                                        album.artwork = response
                                        
                                        ImageAPI.getItemImage(itemId: albumResult.id!, imageType: .primary, width: 250, height: 250, apiResponseQueue: JellyfinAPI.apiResponseQueue)
                                            .sink(receiveCompletion: { completion in
                                                print("Album art thumbnail retrieval \(completion)")
                                            }, receiveValue: { response in
                                                album.thumbnail = response
                                            })
                                            .store(in: &self.cancellables)
                                    })
                                    .store(in: &self.cancellables)
                            }
                        })
                        
                        if response.items!.last == albumResult {
                            complete()
                        }
                    })
                }
            })
            .store(in: &self.cancellables)
    }
    
    func retrieveAlbum(albumId: String, complete: @escaping (Album) -> Void) {
        
        print("Retrieving album \(albumId)")
        
        let fetchRequest = Album.fetchRequest()

        fetchRequest.predicate = NSPredicate(format: "jellyfinId == %@", albumId)
        
        var albumStoreResult : [Album] = []
            
        albumStoreResult = try! JellyfinService.context.fetch(fetchRequest)
            
        if !albumStoreResult.isEmpty {
            
            print("Album found in Core Data \(albumId)")

            print("Returning album \(albumId)")
            
            complete(albumStoreResult[0])
        } else {
                        
            print("Item not found in Core Data, retrieving from API \(albumId)")
            
            ItemsAPI.getItems(userId: self.userId, ids: [albumId], apiResponseQueue: JellyfinAPI.apiResponseQueue)
                .sink(receiveCompletion: { completion in
                    print("Album retrieval \(completion)")
                }, receiveValue: { response in
                    
                    if response.items != nil && response.items!.first != nil {
                        
                        let albumDto = response.items!.first
                        
                        let album = Album(context: JellyfinService.context)
                                            
                        album.jellyfinId = albumDto!.id
                        album.name = albumDto!.name
                        album.productionYear = Int16(albumDto!.productionYear ?? 0)
                        
                        // Retrieve Album Thumbnail and Image
                        ImageAPI.getItemImage(itemId: albumDto!.id!, imageType: .primary)
                            .sink(receiveCompletion: { completion in
                                print("Album art retrieval \(completion)")
                            }, receiveValue: { response in
                                
                                print("Handling album art response \(album.name)")
                                album.artwork = response
                                
                                ImageAPI.getItemImage(itemId: albumDto!.id!, imageType: .primary, width: 250, height: 250, apiResponseQueue: JellyfinAPI.apiResponseQueue)
                                    .sink(receiveCompletion: { completion in
                                        print("Album art thumbnail retrieval \(completion)")
                                    }, receiveValue: { response in
                                        album.thumbnail = response
                                    })
                                    .store(in: &self.cancellables)
                                
                            })
                            .store(in: &self.cancellables)
                        
//                        self.artistService.retrieveArtist(artistId: albumDto!.albumArtist!, complete: { artist in
//                            
//                            album.addToAlbumArtists(artist)
//                            complete(album)
//                        })
                        
                        complete(album)
                    }
                })
                .store(in: &cancellables)
            
//            ItemLookupAPI.applySearchCriteria(itemId: albumId, remoteSearchResult: RemoteSearchResult(name: nil, providerIds: nil, productionYear: nil, indexNumber: nil, indexNumberEnd: nil, parentIndexNumber: nil, premiereDate: nil, imageUrl: nil, searchProviderName: nil, overview: nil, artists: nil))
//                .sink(receiveCompletion: { completion in
//                    print("Completed Album Lookup")
//                }, receiveValue: { response in
//                    print(response)
//                })
//                .store(in: &cancellables)

//            self.get(url: "/Users/\(self.userId)/Items/\(albumId)", params: [
//                "includeItemTypes": "MusicAlbum",
//                "recursive": "true"
//                
//            ], completion: { data in
//                                   
//                let json = try? JSONSerialization.jsonObject(with: data, options: [])
//                
//                print(json!)
//                
//                let albumResult = try? self.decoder.decode(AlbumResult.self, from: data)
//                                                   
//                if albumResult != nil {
//                    
//                    // Attempt to retrieve album from CoreData
//                    
//                    let fetchRequest: NSFetchRequest<Album> = Album.fetchRequest()
//
//                    fetchRequest.predicate = NSPredicate(
//                        format: "jellyfinId == %@", albumResult!.id
//                    )
//                    
//                    do {
//                        let albums : [Album] = try JellyfinService.context.fetch(fetchRequest)
//                        
//                        var album = albums.first ?? Album(context: JellyfinService.context)
//
//                        if album.jellyfinId == nil {
//                        
//                            album = Album(context: JellyfinService.context)
//                                                
//                            album.jellyfinId = albumResult!.id
//                            album.name = albumResult!.name
//                            album.productionYear = Int16(albumResult!.productionYear ?? 0)
//                            
//                            try JellyfinService.context.save()
//                            
//                            print("Returning album \(albumId)")
//                        }
//                        
//                        complete(album)
//                    } catch {
//                        print(error)
//                    }
//                } else {
//                    print("WTF")
//                }
//            })

        }
    }
}
