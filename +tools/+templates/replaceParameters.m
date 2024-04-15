function replaceParameters(templateName, options)
%REPLACEPARAMETERS takes a template name and options and applies
% the replacement specified in options onto the template.
% afterwards it writes this new file to the given outputfile

[k,v] = options.getReplacements();

newCode = fileread(templateName);

for ii = 1:length(k)
    key = ['<<', k{ii}, '>>'];
    newCode = strrep(newCode, key, v{ii});
end

if isempty(options.outputFile)
    outputFile = 'test.m';
else
    outputFile = options.outputFile;
end

fid=fopen(outputFile, 'w');
fprintf(fid, '%s', newCode);
fclose(fid);

end

