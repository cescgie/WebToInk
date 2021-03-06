module WebToInk.Converter.Download
    ( downloadAndSaveImages
    , downloadPage
    , savePage
    , getSrcFilePath
    ) where

import System.Directory (createDirectoryIfMissing, setCurrentDirectory, doesFileExist)
import System.IO (hPutStr, withFile, IOMode(..), writeFile)
import System.FilePath (takeFileName, takeDirectory, combine)
import Data.List (isPrefixOf)

import qualified Data.ByteString.Lazy as L

import Test.HUnit

import WebToInk.Converter.Types
import WebToInk.Converter.Constants (pagesFolder, imagesFolder)
import WebToInk.Converter.Utils (openUrl, downloadByteString)
import WebToInk.Converter.Logger

downloadAndSaveImages :: FilePath ->  Url -> Url -> [Url] -> IO [()]
downloadAndSaveImages targetFolder rootUrl pageUrl imageUrls = do
    createDirectoryIfMissing False fullPathImagesFolder
    mapM (downloadAndSaveImage fullPathImagesFolder rootUrl pageUrl) imageUrls
  where fullPathImagesFolder = combine targetFolder imagesFolder

downloadPage ::  Url -> IO (Maybe String)
downloadPage = openUrl . cleanUrl

savePage :: FilePath ->  FilePath -> String -> IO ()
savePage targetFolder fileName pageContents = do
    createDirectoryIfMissing False fullPagesFolder
    writeFile (combine fullPagesFolder fileName) pageContents 
  where fullPagesFolder = combine targetFolder pagesFolder

downloadAndSaveImage :: FilePath -> Url -> Url -> Url -> IO ()
downloadAndSaveImage targetFolder rootUrl pageUrl url = do
    let fullUrl = resolveUrl rootUrl pageUrl url
    let fullPath = getSrcFilePath targetFolder url

    imageWasDownloadedBefore <- doesFileExist fullPath 
    if imageWasDownloadedBefore 
        then return undefined
        else do 
            logt $ "Downloading image: " ++ fullUrl
            byteString <- downloadByteString fullUrl
            case byteString of 
                Nothing      -> return () 
                (Just bytes) -> L.writeFile fullPath bytes


resolveUrl :: Url -> Url -> Url -> Url
resolveUrl rootUrl pageUrl url
        | "http://"  `isPrefixOf` url = cleanedUrl
        | "https://" `isPrefixOf` url = cleanedUrl
        | "/"        `isPrefixOf` url = rootUrl ++ cleanedUrl
        | otherwise                   = pageFolder ++ "/" ++ cleanedUrl
        where pageFolder = takeDirectory pageUrl
              cleanedUrl = cleanUrl url

cleanUrl = takeWhile (\x -> x /= '?' && x /= '#')

getSrcFilePath :: FilePath -> Url -> FilePath
getSrcFilePath targetFolder url = combine targetFolder $ takeFileName url

-----------------------
-- ----  Tests  ---- --
-----------------------

resolveUrlTests = 
    [ assertEqual "resolving relative to page url appends it to page url"
        resolvedToPageUrl (resolveUrl root page relativeToPageUrl) 
    , assertEqual "resolving relative to root url appends it to root url"
        resolvedToRootUrl (resolveUrl root page relativeToRootUrl) 
    , assertEqual "resolving absolute url returns it as is"
        absoluteUrl (resolveUrl root page absoluteUrl)
    , assertEqual "resolving image url containing ?" 
       "http://some/image.png" (resolveUrl root page "http://some/image.png?query")
    ]
    where 
        root = "http://my.root.url"
        relativeToRootUrl = "/a/b/some.png" -- / means root 
        resolvedToRootUrl = root ++ relativeToRootUrl

        page = "http://my.root.url/pages/page.html"
        relativeToPageUrl = "a/b/some.png"
        resolvedToPageUrl = "http://my.root.url/pages/a/b/some.png"

        absoluteUrl = "http://some.absolute.com"

getSrcFilePathTests = 
    [ assertEqual "getting file path for valid image url"
        (getSrcFilePath targetFolder imgUrl) (targetFolder ++ "/" ++ imgFileName)
    ]
    where
        targetFolder = "someFolder"
        imgFileName = "some.png"
        imgUrl = "/images/" ++ imgFileName
        
tests = TestList $ map TestCase $
    resolveUrlTests ++ 
    getSrcFilePathTests 

runTests = runTestTT tests
