var express = require('express')
var app = express()

app.use(express.static('public'))

app.get('/', function (req, res) {
  res.send('See http://localhost:3000/draft_review.html for example.')
})

app.listen(3000, function () {
  console.log(
    "Demo server listening at http://localhost:3000/.  " +
    "See http://localhost:3000/draft_review.html for example."
  )
})
