import os, httpclient
import strutils
import times
import asyncdispatch

type LinkCheckResult = ref object
  link: string
  state: bool

# Check a link sequentially
proc checkLink(link: string) : LinkCheckResult =
  var client = newHttpClient()
  try:
    return LinkCheckResult(link: link, state:client.get(link).code == Http200)
  except:
    return LinkCheckResult(link:link, state:false)

# Take a array of links, and check them sequentially
proc sequentialLinksChecker(links: seq[string]): void =
  for index, link in links:
    if link.strip() != "":
      let result = checkLink(link)
      echo result.link, " is ", result.state

proc checkLinkAsync(link: string): Future[LinkCheckResult] {.async.} =
  var client = newAsyncHttpClient()

  let future = client.get(link)
  yield future
  if future.failed:
    return LinkCheckResult(link:link, state:false)
  else:
    let resp = future.read()
    return LinkCheckResult(link:link, state: resp.code == Http200)

proc asyncLinksChecker(links: seq[string]) {.async.} =
  var futures = newSeq[Future[LinkCheckResult]]()
  for index, link in links:
    if link.strip() != "":
      futures.add(checkLinkAsync(link))

  let done = await all(futures)
  for x in done:
    echo x.link, " is ", x.state

proc main()=
    echo "Param count: ", paramCount()
    if paramCount() == 1:
        let linksfile = paramStr(1)
        var f = open(linksfile, fmRead)
        let links = readAll(f).splitLines()
        echo "LINKS: " & $links
        echo "SEQUENTIAL:: "
        var t = epochTime()
        sequentialLinksChecker(links)
        echo epochTime()-t
        echo "ASYNC:: "
        t = epochTime()
        waitFor asyncLinksChecker(links)
        echo epochTime()-t

    else:
        echo "Please provide linksfile"
main()
