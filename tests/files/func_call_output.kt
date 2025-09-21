@Composable
private fun TextFooterView(text: String) {
    Text(
        text,
        modifier = Modifier.padding(start = (LEADING_PADDING + 12).dp),
        fontSize = FOOTNOTE_FONT_SIZE.sp,
        fontStyle = FontStyle.Italic,
        maxLines = 1,
        color = MaterialTheme.colorScheme.outline,
    )
}

