package NCI::TARGET::Circos;

use Dancer qw(:syntax);
use Dancer::Plugin::Thumbnail;
use File::Basename qw(basename fileparse);
use Image::Size qw(imgsize);

our $VERSION = '0.1';

# defaults
my $default_num_display_cols = 3;
my $default_image_w = 500;
my $default_overlay_image_w = 800;
my $default_legend_image_w = 100;
my $lightbox_image_w = 700;
my $image_file_ext = 'png';
my $legend_file_name_regexp = qr/legend\..+?$/i;

sub by_adj_image_file_name {
    my $a_basename = fileparse($a, qr/\.[^.]*/);
    my $b_basename = fileparse($b, qr/\.[^.]*/);
    my @a_basename_parts = split '_', $a_basename, 3;
    my @b_basename_parts = split '_', $b_basename, 3;
    if (scalar(@a_basename_parts) == 3 and scalar(@b_basename_parts) == 3) {
        # adjust case ID if CGI has added trailing integer e.g. TARGET-30-NAABZL-2 -> TARGET-30-NAABZL
        $a_basename_parts[1] = join('-', (split('-', $a_basename_parts[1]))[0..2]);
        # adjust case ID if CGI has added trailing integer e.g. TARGET-30-NAABZL-2 -> TARGET-30-NAABZL
        $b_basename_parts[1] = join('-', (split('-', $b_basename_parts[1]))[0..2]);
        return join('_', @a_basename_parts) cmp join('_', @b_basename_parts);
    }
    elsif (scalar(@a_basename_parts) == 3) {
        return -1;
    }
    elsif (scalar(@b_basename_parts) == 3) {
        return 1;
    }
}

get '/' => sub {
    template 'index';
};

get qr/^\/([^\/]+)\/?([^\/]+)?\/?$/ => sub {
    my ($disease_proj, $subproj) = splat;
    my (@image_files, @circos_types, @target_case_ids, 
        @cmp_types, %num_cmp_type_images, @subprojects);
    my $disease_proj_image_dir = config->{'public'} . "/$disease_proj/images";
    # subprojects (i.e. subdirectories)
    for my $file (<$disease_proj_image_dir/*>) {
        push @subprojects, (fileparse($file))[0] if -d $file;
    }
    my $image_dir = $disease_proj_image_dir;
    if ($subproj and -d "$disease_proj_image_dir/$subproj") {
        $image_dir .= "/$subproj";
    }
    # legend
    my ($legend_file_name) = grep { m/$legend_file_name_regexp/ } <$disease_proj_image_dir/*.$image_file_ext>;
    my $legend_file_basename = fileparse($legend_file_name, qr/\.[^.]*/) if defined $legend_file_name;
    # images
    for my $image_file_name (sort by_adj_image_file_name <$image_dir/*.$image_file_ext>) {
        my $image_file_basename = fileparse($image_file_name, qr/\.[^.]*/);
        if (defined $legend_file_basename and $image_file_basename ne $legend_file_basename) {
            push @image_files, basename($image_file_name);
            my ($circos_type, $target_case_id, $disease_state_cmp_type) = split /_/, $image_file_basename, 3;
            push @circos_types, $circos_type;
            # adjust case ID if CGI has added trailing integer e.g. TARGET-30-NAABZL-2 -> TARGET-30-NAABZL
            $target_case_id = join('-', (split('-', $target_case_id))[0..2]);
            push @target_case_ids, $target_case_id;
            push @cmp_types, $disease_state_cmp_type;
            $num_cmp_type_images{$disease_state_cmp_type}++;
        }
    }
    my @unique_cmp_types = sort keys %num_cmp_type_images;
    my ($legend_w, $legend_h) = imgsize($legend_file_name) if defined $legend_file_name;
    my $app_title_prefix = join(' ', (split '::', __PACKAGE__)[0..1]);
    template 'circos' => {
        'page_title' => 
            "$app_title_prefix $disease_proj" . 
            ( $subproj ? " $subproj" : '' ) . 
            ' CGI Circos Plots',
        'disease_proj' => $disease_proj,
        'subproj' => $subproj,
        'subprojs' => \@subprojects,
        'circos_types' => \@circos_types,
        'target_case_ids' => \@target_case_ids,
        'cmp_types' => \@cmp_types,
        'unique_cmp_types' => \@unique_cmp_types,
        'num_cmp_type_images' => \%num_cmp_type_images,
        'num_display_cols' => 
            param('arrange_by') 
                ? scalar(@unique_cmp_types) 
                : ( param('cols') || $default_num_display_cols ),
        'image_files' => \@image_files,
        'legend_file' => 
            $legend_file_name 
                ? basename($legend_file_name)
                : '',
        'arrange_by' => param('arrange_by'),
        'image_w' => param('tsize') || $default_image_w,
        'legend_image_w' => $default_legend_image_w,
        'overlay_image_w' => $default_overlay_image_w,
        'legend_w' => $legend_w,
        'legend_h' => $legend_h,
        'lightbox_image_w' => $lightbox_image_w,
    };
};


get '/:disease_proj/resized/:resize_image_w/:image_file_name' => sub {
    my $is_legend = param('image_file_name') =~ /$legend_file_name_regexp/ ? 1 : 0;
    resize param('disease_proj') . '/images/' . param('image_file_name') => {
        w => param('resize_image_w') || ( $is_legend ? $default_legend_image_w : $default_image_w ),
    };
};

get '/:disease_proj/:subproj/resized/:resize_image_w/:image_file_name' => sub {
    my $is_legend = param('image_file_name') =~ /$legend_file_name_regexp/ ? 1 : 0;
    resize param('disease_proj') . '/images/' . ( !$is_legend ? param('subproj') . '/' : '' ) . param('image_file_name') => {
        w => param('resize_image_w') || ( $is_legend ? $default_legend_image_w : $default_image_w ),
    };
};

get '/:disease_proj/image/:image_file_name' => sub {
    send_file param('disease_proj') . '/images/' . param('image_file_name');
};

get '/:disease_proj/:subproj/image/:image_file_name' => sub {
    my $is_legend = param('image_file_name') =~ /$legend_file_name_regexp/ ? 1 : 0;
    send_file param('disease_proj') . '/images/' . ( !$is_legend ? param('subproj') . '/' : '' ) . param('image_file_name');
};

get qr/^\/([^\/]+)\/([^\/]+)?\/?overlay\/?$/ => sub {
    my ($disease_proj, $subproj) = splat;
    my $image_file_0_basename = fileparse(param('img0'), qr/\.[^.]*/);
    my (undef, $target_case_id_0, $disease_state_cmp_type_0) = split '_', $image_file_0_basename, 3;
    my $image_file_1_basename = fileparse(param('img1'), qr/\.[^.]*/);
    my (undef, $target_case_id_1, $disease_state_cmp_type_1) = split '_', $image_file_1_basename, 3;
    template 'circos_overlay' => {
        'disease_proj' => $disease_proj,
        'subproj' => $subproj,
        'image_w' => param('tsize') || $default_overlay_image_w,
        'case_id_0' => $target_case_id_0,
        'case_id_1' => $target_case_id_1,
        'image_file_0' => param('img0'),
        'image_file_1' => param('img1'),
        'label_file_0' => $disease_state_cmp_type_0,
        'label_file_1' => $disease_state_cmp_type_1,
    }, {
        layout => 'overlay',
    };
};

true;
