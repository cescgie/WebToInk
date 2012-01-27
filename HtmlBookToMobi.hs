import HtmlPages(getHtmlPages)
import Images(getImages)
import Download(downloadPage, savePage, downloadAndSaveImages, getSrcFilePath)
import Types
import Constants

import System.Directory(createDirectoryIfMissing, setCurrentDirectory)
import Control.Monad(forM)
import Data.String.Utils(replace)

import Test.HUnit

main = do 
    let url = "http://book.realworldhaskell.org/read/"
    let rootUrl = "http://book.realworldhaskell.org/"

    pagesDic <- getHtmlPages url

    let folder = "real-haskell-book"
    createDirectoryIfMissing False folder 

    setCurrentDirectory folder

    downloadPages rootUrl pagesDic

    setCurrentDirectory ".."

downloadPages rootUrl pagesDic = do
    forM pagesDic (\(fileName, url) -> do
        putStrLn $ "Downloading: " ++ fileName
        pageContents <- downloadPage url

        let imageUrls = getImages pageContents
        putStrLn $ "Downloading contained images: " ++ (show imageUrls)
        downloadAndSaveImages rootUrl imageUrls

        let localizedPageContents = 
                localizeSrcUrls ("../" ++ imagesFolder) pageContents imageUrls 
        putStrLn "Saving page "
        savePage fileName localizedPageContents
        )

localizeSrcUrls :: FilePath -> PageContents -> [Url] -> PageContents
localizeSrcUrls targetFolder pageContents srcUrls =
    foldr (\srcUrl contents -> 
        replace ("src=\"" ++ srcUrl) ("src=\"" ++ (getSrcFilePath targetFolder srcUrl)) contents) 
        pageContents srcUrls

-- ===================
-- Tests
-- ===================

localizeSrcUrlsTests =
    [ assertEqual "localizing src urls"
        (localizeSrcUrls filePath pageContents imageUrls) localizedPageContents 
    ]
    where
        filePath = "../images"
        pageContents = 
            "<body>" ++
                "<img src=\"/support/figs/rss.png\"/>" ++
                "<span>some span</span>" ++
                "<img src=\"/support/figs/ball.png\"/>" ++
            "</body>"
        imageUrls = [ "/support/figs/rss.png", "/support/figs/ball.png" ]
        localizedPageContents =
            "<body>" ++
                "<img src=\"" ++ filePath ++ "/rss.png\"/>" ++
                "<span>some span</span>" ++
                "<img src=\"" ++ filePath ++ "/ball.png\"/>" ++
            "</body>"


tests = TestList $ map TestCase $
    localizeSrcUrlsTests 

runTests = do
    runTestTT tests
