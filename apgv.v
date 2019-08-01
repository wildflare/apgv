// Air Pressure Graph

import http

const (
	BP_RANGE = 21
	TIME_RANGE = 24
	GRAPH_CENTER = TIME_RANGE / 2
	MAGNIFICATION = 4

 	YESTERDAY_URL = 'http://www.jma.go.jp/jp/amedas_h/yesterday-44132.html'
	TODAY_URL = 'http://www.jma.go.jp/jp/amedas_h/today-44132.html'

)


fn get_web_body(url string)  string {
	html := http.get_text(url)
	return html
}


fn scraype_pressure_data(body string) []f32 {
	mut data := []f32
	mut pos := 0
	mut lasttime := 0
	
	searchword := '"block middle">'
	for i:=0; ; i++{
		pos = body.index_after(searchword, pos + 1)
		if pos == -1 {
			break
		}
		end := body.index_after('<', pos)
			
		if i % 7 == 6 {
			// println(html.substr(pos, end))
			s := body.substr(pos+searchword.len, end)
			if(s == '&nbsp;') {
				break
			}
			//println(s)
			data << s.f32()
			lasttime++
		}
	} 
	return data
}


fn scraype_date_time(body string) string {
	searchword := '<td class="td_title height2" colspan="3">'
	endword := '</td>'

	mut pos := 0
	pos = body.index_after(searchword, pos + 1)
	end := body.index_after(endword, pos)
 
	return body.substr(pos + searchword.len, end)
}

//四捨五入
fn round(f f32) int {
    return int(f + 0.5)
}


fn get_time_offset(data []f32) int {
    return data.len - TIME_RANGE + 1
}

fn get_range_offset(data []f32) int {
    n := data.len
    return round(data[n - GRAPH_CENTER]) + (BP_RANGE / 2 / MAGNIFICATION)
}


fn set_field(field mut []array_int, data []f32){
	for i := 0; i < BP_RANGE; i++ {
		*field << [0; TIME_RANGE]
 	}

	r_offset := get_range_offset(data)
	t_offset := get_time_offset(data) -1

    for x:=0; x < TIME_RANGE; x++ {
		mut y := r_offset * MAGNIFICATION - round(data[x + t_offset] * MAGNIFICATION)
        if y > 0 && y < BP_RANGE {
            field[y][x] = 1
        }
    }

}


fn print_field(field []array_int, data []f32) {
	r_offset := get_range_offset(data)
	t_offset := get_time_offset(data)

	println('')
	println('      時刻→')
	print('↓気圧')
	for i in t_offset..t_offset + 24 {
		print('${i%24:3d}')
	}
	println('')


	for i,line in field {
		mut s:=''
		mut dot := '...'
		mut atmark := ' @ '

		step := f32(r_offset)- (f32(i) / MAGNIFICATION)
//		print('${step:6.1f}')
		if int(step*10) % 10 == 0 {
			print(' ${int(step):04d} ')
			dot = '...'
			atmark = '.@.'
		} else {
			print('      ')
			dot = '   '
			atmark = ' @ '
		}

		for cell in line {
			s += if cell == 1 { atmark } else { dot }
		}
		println(s)
	}
}


fn main() {

	mut data := []f32
	mut body := ''
	mut dt := []f32

	body = get_web_body(YESTERDAY_URL)
	dt = scraype_pressure_data(body)
	data << dt

	body = get_web_body(TODAY_URL)
	dt = scraype_pressure_data(body)
	data << dt

//	for d in data {
//		println(d)
//	}

	mut field := []array_int
	set_field(mut field, data)

	print_field(field, data)

	println('\t\t\t ${scraype_date_time(body)}\n')


}

